require "omnicontacts/http_utils"
require "json"

module OmniContacts
  module Authorization
    module OAuth2
      include HTTPUtils

      def authorization_url
        "https://" + auth_host + authorize_path + "?" + authorize_url_params
      end

      private

      def authorize_url_params
        to_query_string({
          :client_id => client_id,
          :scope => encode(scope),
          :response_type => "code",
          :access_type => "offline",
          :approval_prompt => "force",
          :redirect_uri => encode(redirect_uri)
        })    
      end

      public

      def fetch_access_token code
        access_token_from_response https_post(auth_host, request_token_path, token_req_params(code))
      end

      private

      def token_req_params code
        {
          :client_id => client_id,
          :client_secret => client_secret,
          :code => code,
          :redirect_uri => encode(redirect_uri),
          :grant_type => "authorization_code"
        }
      end

      def access_token_from_response response
        puts "raw response is " + response
        json = JSON.parse(response)
        raise json["error"] if json["error"]
        [ json["access_token"], json["token_type"], json["refresh_token"] ]
      end

      public

      def refresh_access_token refresh_token
        access_token_from_response https_post(auth_host, request_token_path, refresh_token_req_params(refresh_token))
      end

      private

      def refresh_token_req_params refresh_token
        {
          :client_id => client_id,
          :client_secret => client_secret,
          :refresh_token => refresh_token,
          :grant_type => "refresh_token"
        }
        
      end
    end
  end
end
