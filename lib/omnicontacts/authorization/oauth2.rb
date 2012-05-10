require "omnicontacts/http_utils"
require "json"

# This module represents an OAuth 2.0 client.
#
# Classes including the module must implement
# the following methods:
# * auth_host -> the host of the authorization server
# * authorize_path -> the path on the authorization server the redirect the use to
# * client_id -> the registered client id of the client
# * client_secret -> the registered client secret of the client
# * redirect_path -> the path the authorization server has to redirect the user back after authorization
# * auth_token_path -> the path to query once the user has granted permission to the application
# * scope -> the scope necessary to acquire the contacts list.
module OmniContacts
  module Authorization
    module OAuth2
      include HTTPUtils

      # Calculates the URL the user has to be redirected to in order to authorize
      # the application to access his contacts list.
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

      # Fetches the access token from the authorization server using the given authorization code.
      def fetch_access_token code
        access_token_from_response https_post(auth_host, auth_token_path, token_req_params(code))
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
        json = JSON.parse(response)
        raise json["error"] if json["error"]
        [json["access_token"], json["token_type"], json["refresh_token"]]
      end

      public

      # Refreshes the access token using the provided refresh_token.
      def refresh_access_token refresh_token
        access_token_from_response https_post(auth_host, auth_token_path, refresh_token_req_params(refresh_token))
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
