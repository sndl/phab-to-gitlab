#!/usr/bin/env ruby

require 'yaml'
require 'gitlab'
require 'securerandom'
require_relative 'lib/phabricator.rb'

CONFIG = YAML.load_file("#{__dir__}/config.yml")
METHOD = ARGV[0]

@phab = Phabricator.new(
  CONFIG['phabricator']['url'],
  CONFIG['phabricator']['api-token']
)

@gitlab = Gitlab.client(
  endpoint: CONFIG['gitlab']['url'],
  private_token: CONFIG['gitlab']['private-token']
)

def migrate_user
  @phab.user_search.each do |u|
    email = "#{u['fields']['username']}@#{CONFIG['email_domain']}"
    CONFIG['generate_password'] ? password = SecureRandom.hex(4) : password = ''
    username = u['fields']['username']
    p name = u['fields']['realName']

    user = @gitlab.create_user(email, password, username, name: name)

    gitlab.block_user(user.id) if u['fields']['roles'].include? 'disabled'
  end
end

case METHOD
when 'user'
  migrate_user
else
  puts 'Method is not available. Available methods are: user'
end
