#!/usr/bin/env ruby

require 'yaml'
require 'time'
require 'securerandom'
require 'open-uri'
require 'fileutils'
require_relative 'lib/phabricator.rb'
require_relative 'lib/gitlab.rb'

CONFIG = YAML.load_file("#{__dir__}/config.yml")
MAPPING = YAML.load_file("#{__dir__}/mapping.yml")
METHOD = ARGV[0]

@phab = Phabricator.new(
  CONFIG['phabricator']['url'],
  CONFIG['phabricator']['api-token']
)

@gitlab = Gitlab.client(
  endpoint: CONFIG['gitlab']['url'],
  private_token: CONFIG['gitlab']['private-token']
)

Gitlab.sudo = 'phab'

def migrate_user
  @phab.user_search.each do |u|
    email = "#{u['fields']['username']}@#{CONFIG['email_domain']}"
    CONFIG['generate_password'] ? password = SecureRandom.hex(4) : password = ''
    username = u['fields']['username']
    p name = u['fields']['realName']

    user = @gitlab.create_user(email, password, username, name: name)

    @gitlab.block_user(user.id) if u['fields']['roles'].include? 'disabled'
  end
end

def migrate_ticket
  MAPPING.each do |k, v|
    options = {
      constraints: {
        projects: [k]
      },
      order: 'oldest'
    }

    @phab.maniphest_search(options).each do |m|
      info = @phab.maniphest_info(m['id'])
 
      ## Variables     
      title = m['fields']['name']

      puts "Importing: \"#{title}\""

      project_name = v
      author = @phab.user_search({ constraints: { phids: [info['authorPHID']] } })[0]['fields']['username']
      date_created = info['dateCreated']
      is_closed = info["isClosed"]

      if info['ownerPHID'].nil?
        assignee = nil
      else
        assignee = @phab.user_search({ constraints: { phids: [info['ownerPHID']] } })[0]['fields']['username']
      end

      description = info['description']
      description = Phabricator.format_message(description) unless description.nil?
      description.scan(/{F([0-9]+)}/) do |id|
        @phab.file_search({ constraints: { ids: [id[0].to_i] } }).each do |f|
          file_name = f['fields']['name']
          file_url = f['fields']['dataURI']
          digest = SecureRandom.hex(16)

          description = description.sub("{F#{id[0]}}", "[#{file_name}](/uploads/#{digest}/#{file_name})")

          download = open(file_url)
          path = "uploads/#{project_name}/#{digest}/"
          FileUtils.mkpath(path)
          IO.copy_stream(download, "#{path}/#{file_name}") 
        end
      end

      options = {
        description: description,
        created_at: Time.at(date_created.to_i).iso8601,
        assignee_id: @gitlab.user_search(assignee)[0].id
      }
      options[:labels] = "critical" if info['priority'] == "Unbreak Now!"

      ## Migrate tickets
      iid = @gitlab.create_issue(project_name, title, author, options).iid
      @gitlab.close_issue(project_name, iid) if info['isClosed']

      ## Migrate comments
      @phab.maniphest_gettasktransactions(m['id']).each do |tx|
        if tx['transactionType'] == 'core:comment'
          date = Time.at(tx['dateCreated'].to_i).iso8601
          author =  @phab.user_search({ constraints: { phids: [tx['authorPHID']] } })[0]['fields']['username']
          text = tx['comments']
          text = Phabricator.format_message(text) unless text.nil?

          next if text.nil?

          text.scan(/{F([0-9]+)}/) do |id|
            @phab.file_search({ constraints: { ids: [id[0].to_i] } }).each do |f|
              file_name = f['fields']['name']
              file_url = f['fields']['dataURI']
              digest = SecureRandom.hex(16)

              text = text.sub("{F#{id[0]}}", "[#{file_name}](/uploads/#{digest}/#{file_name})")

              download = open(file_url)
              path = "uploads/#{project_name}/#{digest}/"
              FileUtils.mkpath(path)
              IO.copy_stream(download, "#{path}/#{file_name}") 
            end
          end
          @gitlab.create_issue_note(project_name, iid, text, author, date)
        end
      end
    end
  end
end

case METHOD
when 'user'
  migrate_user
when 'ticket'
  migrate_ticket
when 'all'
  migrate_user
  migrate_ticket
else
  puts 'Method is not available. Available methods are: user, ticket, all'
end
