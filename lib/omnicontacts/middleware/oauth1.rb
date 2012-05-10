require "omnicontacts/authorization/oauth1"
require "omnicontacts/middleware/base_oauth"

# This class is an OAuth 1.0 Rack middleware.
#
# Extending classes are required to 
# implement the following methods:
# * fetch_token_from_token_and_verifier -> this method has to
#   fetch the list of contacts from the authorization server.
module OmniContacts
  module Middleware
    class OAuth1 < BaseOAuth
      include Authorization::OAuth1

      attr_reader :consumer_key, :consumer_secret, :callback_path

      def initialize app, consumer_key, consumer_secret, options = {}
        super app, options
        @consumer_key = consumer_key
        @consumer_secret = consumer_secret
        @callback_path = options[:callback_path] || "/contacts/#{class_name}/callback"
        @token_prop_name = "#{base_prop_name}.oauth_token"
      end

      def callback
        host_url_from_rack_env(@env) + callback_path
      end

      alias :redirect_path :callback_path

      # Obtains an authorization token from the server,
      # stores it and the session and redirect the user
      # to the authorization website.
      def request_authorization_from_user
        (auth_token, auth_token_secret) = fetch_authorization_token
        session[@token_prop_name] = auth_token
        session[token_secret_prop_name(auth_token)] = auth_token_secret
        redirect_to_authorization_site(auth_token)
      end

      def token_secret_prop_name oauth_token
        "#{base_prop_name}.#{oauth_token}.oauth_token_secret"
      end

      def redirect_to_authorization_site auth_token
        [302, {"location" => authorization_url(auth_token)}, []]
      end

      # Parses the authorization token from the query string and 
      # obtain the relative secret from the session.
      # Finally it calls fetch_contacts_from_token_and_verifier.
      # If token is found in the query string an AuhorizationError
      # is raised.
      def fetch_contacts
        params = query_string_to_map(@env["QUERY_STRING"])
        oauth_token = params["oauth_token"]
        oauth_verifier = params["oauth_verifier"]
        oauth_token_secret = session[token_secret_prop_name(oauth_token)]
        if oauth_token && oauth_verifier && oauth_token_secret
          fetch_contacts_from_token_and_verifier(oauth_token, oauth_token_secret, oauth_verifier)
        else
          raise AuthorizationError.new("User did not grant access to contacts list")
        end
      end

    end
  end
end
