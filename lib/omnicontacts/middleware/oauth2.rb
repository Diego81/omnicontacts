require "omnicontacts/protocol/oauth2"

module OmniContacts
  class OAuth2Middleware
    include OmniContacts::OAuth2

    attr_reader :client_id, :client_secret, :ssl_ca_file, :auth_host, :authorize_path, :request_token_path, :scope

    def initialize app, client_id, client_secret, options ={}
      @app = app
      @client_id = client_id
      @client_secret = client_secret
      @redirect_path = options[:redirect_path] 
      @ssl_ca_file = options[:ssl_ca_file]
    end
 
    def call env
      @env = env
      if env["PATH_INFO"] == listening_path
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
      contacts_from_code(code) 
    end

    def contacts_from_code(code)
      token, token_type = access_token_from_code(code)
      contacts_from_access_token token, token_type
    end

  end
end
