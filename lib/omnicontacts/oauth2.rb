require "omnicontacts/http_utils"

module OmniContacts
  class OAuth2
    include HTTPUtils

    def redirect_url
      "https://" + auth_host + authorize_path + "?" + authorize_url_params
    end

    private

    def authorize_url_params
      to_query_string({
        :client_id => client_id,
        :scope => encode(scope),
        :response_type => "code",
        :access_type => "online",
        :approval_prompt => "force",
        :redirect_uri => encode(redirect_uri)
      })    
    end

    def access_token_from_code code
      token_response = https_connection(auth_host).request_post(request_token_path, token_req_params(code)) 
      access_token_from_response token_response.body
    end

    def token_req_params code
      to_query_string( {
        :client_id => client_id,
        :client_secret => client_secret,
        :code => code,
        :redirect_uri => encode(redirect_uri),
        :grant_type => "authorization_code"
      })
    end

    def access_token_from_response response
      json = ActiveSupport::JSON.decode(response)
      raise json["error"] if json["error"]
      [json["access_token"], json["token_type"]]
    end

  end

end
