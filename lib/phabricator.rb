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

  private def call(endpoint, data)
    url = "#{@url}#{endpoint}"
    data = { 'api.token' => @api_token }.merge(data)

    JSON.parse(RestClient.post(url, data).body)['result']['data']
  end
end
