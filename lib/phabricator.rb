require 'json'
require 'rest-client'

class Phabricator
  def initialize(url, api_token)
    @url = url
    @api_token = api_token
  end

  def self.format_message(msg)
    msg = msg.gsub(/^\[\]/, '* [ ]').gsub(/^\[x\]/, '* [x]').gsub(/^lang=.*$/, '')

    return msg
  end

  def user_search(options = {})
    endpoint = 'user.search'

    paginate(endpoint, options)
  end

  def file_search(options = {})
    endpoint = 'file.search'

    paginate(endpoint, options)
  end

  def maniphest_search(options = {})
    endpoint = 'maniphest.search'

    paginate(endpoint, options)
  end

  def maniphest_info(task_id)
    endpoint = 'maniphest.info'
    payload = { task_id: task_id }

    call(endpoint, payload)
  end

  def maniphest_gettasktransactions(task_id)
    endpoint = 'maniphest.gettasktransactions'
    payload = { ids: [task_id.to_s] }

    call(endpoint, payload)[task_id.to_s]
  end

  private def call(endpoint, payload)
    url = "#{@url}#{endpoint}"
    payload = { 'api.token' => @api_token }.merge(payload)

    JSON.parse(RestClient.post(url, payload).body)['result']
  end

  private def paginate(endpoint, payload)
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
