#!/usr/bin/env ruby

require 'json'
require 'rest-client'

class Phabricator
  def initialize(url, api_token)
    @url = url
    @api_token = api_token
  end

  def call(endpoint, data)
    url = "#{@url}#{endpoint}"
    JSON.parse(RestClient.post(url, data).body)['result']['data']
  end

  def user_search(options = {})
    endpoint = 'user.search'
    data = { 'api.token' => @api_token }.merge(options)

    call(endpoint, data)
  end
end
