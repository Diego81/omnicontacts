require "omnicontacts/authorization/oauth2"
require "omnicontacts/middleware/base_oauth"

module OmniContacts
  module Middleware
    class OAuth2 < BaseOAuth
      include Authorization::OAuth2

      attr_reader :client_id, :client_secret, :redirect_path

      def initialize app, client_id, client_secret, options ={}
        super app, options
        @client_id = client_id
        @client_secret = client_secret
        @redirect_path = options[:redirect_path] 
        @ssl_ca_file = options[:ssl_ca_file]
      end

      def request_authorization_from_user
        [302, {"location" => authorization_url}, []]
      end

      def redirect_uri
        host_url_from_rack_env(@env) + redirect_path
      end

      def fetch_contacts
        code =  query_string_to_map(@env["QUERY_STRING"])["code"]
        if code
          refresh_token = session[refresh_token_prop_name(code)]
          (access_token, token_type, refresh_token) = if refresh_token
                                                        refresh_access_token(refresh_token)
                                                      else
                                                        fetch_access_token(code)
                                                      end
          contacts = fetch_contacts_using_access_token(access_token, token_type)
          session[refresh_token_prop_name(code)] = refresh_token if refresh_token
          contacts
        else
          raise AuthorizationError.new("User did not grant access to contacts list")
        end
      end

      def refresh_token_prop_name code
        "#{base_prop_name}.#{code}.refresh_token"
      end

    end
  end
end
