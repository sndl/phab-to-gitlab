#!/usr/bin/env ruby

require 'json'
require 'rest-client'

class Phabricator
  def initialize(url, api_token)
    @url = url
    @api_token = api_token
  end

  def user_search(options = {})
    endpoint = 'user.search'

    call(endpoint, options)
  end

  def maniphest_search(options = {})
    endpoint = 'maniphest.search'

    call(endpoint, options)
  end

  def maniphest_info(task_id)
    endpoint = 'maniphest.info'
    url = "#{@url}#{endpoint}"

    JSON.parse(RestClient.post(url, { task_id: task_id, 'api.token': @api_token}).body)['result']
  end

  private def call(endpoint, payload)
    url = "#{@url}#{endpoint}"
    payload = { 'api.token' => @api_token }.merge(payload)
    data = []
   
    loop do 
      response = JSON.parse(RestClient.post(url, payload).body)['result']
      data.concat(response['data'])

      cursor = response['cursor']['after']
      if cursor.nil?
        break
      else
        payload[:after] = cursor
      end
    end 
    
    data
  end
end
