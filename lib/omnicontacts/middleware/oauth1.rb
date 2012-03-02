require "omnicontacts/authorization/oauth1"

module OmniContacts
  module Middleware
    class OAuth1
      include OmniContacts::Authorization::OAuth1

      attr_reader :consumer_key, :consumer_secret, :ssl_ca_file, :callback_path

      def initialize app, consumer_key, consumer_secret, token_persistence_class, options = {}
        @app = app
        @token_persistence_class = token_persistence_class
        @consumer_key = consumer_key
        @consumer_secret = consumer_secret
        @callback_path = options[:callback_path] 
        @ssl_ca_file = options[:ssl_ca_file]
        @listening_path = "/contacts/" + self.class.name.downcase
      end

      def call env
        @env = env
        if env["PATH_INFO"] == @listening_path
          obtain_token_and_redirect
        else
          if env["PATH_INFO"] =~ /^#{callback_path}/
            env["omnicontacts.contacts"] = fetch_contacts(env)
          end
          @app.call env
        end
      end

      def callback
        host_url_from_rack_env(@env) + callback_path
      end

      private

      def obtain_token_and_redirect
        (auth_token, auth_token_secret) = request_token
        token = @token_persistence_class.new
        token.oauth_token = auth_token
        token.oauth_token_secret = auth_token_secret
        redirect_to_authorization_site(auth_token) if token.save
      end

      def redirect_to_authorization_site auth_token
        [302, {"location" => authorization_url(auth_token)}, []]
      end

      def fetch_contacts env
        params = query_string_to_map(env["QUERY_STRING"])
        token = @token_persistence_class.find_by_oauth_token(params["oauth_token"])
        fetch_contacts_from_token_and_verifier(token.oauth_token, token.oauth_token_secret, params["oauth_verifier"])
      end

    end
  end
end
