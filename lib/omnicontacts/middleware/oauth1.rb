require "omnicontacts/authorization/oauth1"
require "omnicontacts/middleware/base_oauth"

module OmniContacts
  module Middleware
    class OAuth1 < BaseOAuth
      include Authorization::OAuth1

      attr_reader :consumer_key, :consumer_secret, :callback_path

      def initialize app, consumer_key, consumer_secret, options = {}
        super app, options
        @consumer_key = consumer_key
        @consumer_secret = consumer_secret
        @callback_path = options[:callback_path] 
        @base_prop_name = "omnicontacts.#{self.class.name.downcase}"
        @token_prop_name = "#{@base_prop_name}.oauth_token"
      end

      def callback
        host_url_from_rack_env(@env) + callback_path
      end

      alias :redirect_path :callback_path

      private

      def request_authorization_from_user
        (auth_token, auth_token_secret) = request_token
        session[@token_prop_name] = auth_token
        session[token_secret_prop_name(auth_token)] = auth_token_secret
        redirect_to_authorization_site(auth_token) 
      end

      def token_secret_prop_name oauth_token
        "#{@base_prop_name}.#{oauth_token}.oauth_token_secret"  
      end

      def session
        raise "You must provide a session to use OmniContacts" unless @env["rack.session"]
        @env["rack.session"]
      end

      def redirect_to_authorization_site auth_token
        [302, {"location" => authorization_url(auth_token)}, []]
      end

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
