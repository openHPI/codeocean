class Xikolo::Client
  def self.get_user(user_id)
    params = {:user_id => user_id}
    response = get_request(user_profile_url(user_id), params)
    if response
      return JSON.parse(response)
    else
      return nil
    end
  end

  def self.user_profile_url(user_id)
    return url + 'users/' + user_id
  end

  def self.post_request(url, params)
    begin
      return RestClient.post url, params, http_header
    rescue
      return nil
    end
  end

  def self.get_request(url, params)
    begin
      return RestClient.get url, {:params => params}.merge(http_header)
    rescue
      return nil
    end
  end

  def self.http_header
    return {:accept => accept, :authorization => token}
  end

  def self.url
    @url ||= Config.new(:code_ocean).read.fetch(:xikolo_api_url, 'http://localhost:3000/api/') #caches this with ||=, second value of fetch is default value
  end

  def self.accept
    'application/vnd.xikolo.v1, application/json'
  end

  def self.token
    'Token token="'+Rails.application.secrets.openhpi_api_token+'"'
  end

  private

  def authenticate_with_user
    params = {:email => "admin@openhpi.de", :password => "admin"}
    response = post_request(authentication_url, params)
    @token = 'Token token="'+JSON.parse(response)['token']+'"'
  end

  def self.authentication_url
    return @url + 'authenticate'
  end
end