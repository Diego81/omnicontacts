require "omnicontacts/authorization/oauth2"

module OmniContacts
  module Middleware
    class OAuth2
      include OmniContacts::Authorization::OAuth2

      attr_reader :client_id, :client_secret, :ssl_ca_file, :redirect_path

      def initialize app, client_id, client_secret, options ={}
        @app = app
        @client_id = client_id
        @client_secret = client_secret
        @redirect_path = options[:redirect_path] 
        @ssl_ca_file = options[:ssl_ca_file]
        @listening_path = "/contacts/" + self.class.name.downcase
      end

      def call env
        @env = env
        if env["PATH_INFO"] == @listening_path
          redirect_to_authorization_site
        else
          if env["PATH_INFO"] =~ /^#{redirect_path}/
            env["omnicontacts.contacts"] = fetch_contacts
          end
          @app.call(env)
        end
      end

      def redirect_uri
        host_url_from_rack_env(@env) + redirect_path
      end

      private

      def redirect_to_authorization_site
        [302, {"location" => authorization_url }, []]
      end

      def fetch_contacts
        code =  query_string_to_map(@env["QUERY_STRING"])["code"]
        fetch_contacts_from_authorization_code(code) 
      end

    end
  end
end
