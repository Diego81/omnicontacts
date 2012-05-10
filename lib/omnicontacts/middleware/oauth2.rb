require "omnicontacts/authorization/oauth2"
require "omnicontacts/middleware/base_oauth"

# This class is a OAuth 2 Rack middleware.
#
# Extending class are required to implement
# the following methods:
# * fetch_contacts_using_access_token -> it 
#   fetches the list of contacts from the authorization
#   server.
module OmniContacts
  module Middleware
    class OAuth2 < BaseOAuth
      include Authorization::OAuth2

      attr_reader :client_id, :client_secret, :redirect_path

      def initialize app, client_id, client_secret, options ={}
        super app, options
        @client_id = client_id
        @client_secret = client_secret
        @redirect_path = options[:redirect_path] || "/contacts/#{class_name}/callback"
        @ssl_ca_file = options[:ssl_ca_file]
      end

      def request_authorization_from_user
        [302, {"location" => authorization_url}, []]
      end

      def redirect_uri
        host_url_from_rack_env(@env) + redirect_path
      end

      # It extract the authorization code from the query string.
      # It uses it to obtain an access token.
      # If the authorization code has a refresh token associated 
      # with it in the session, it uses the obtain an access token.
      # It fetches the list of contacts and stores the refresh token
      # associated with the access token in the session.
      # Finally it returns the list of contacts.
      # If no authorization code is found in the query string an
      # AuthoriazationError is raised.
      def fetch_contacts
        code = query_string_to_map(@env["QUERY_STRING"])["code"]
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
