require "omnicontacts/oauth2"

module OmniContacts
  class Hotmail < OAuth2

    attr_reader :client_id, :client_secret, :ssl_ca_file, :auth_host, :authorize_path, :request_token_path, :scope

    def initialize app, client_id, client_secret, options = {}
      @app = app
      @client_id = client_id
      @client_secret = client_secret
      @redirect_path = options[:redirect_path] || "/contacts/hotmail/callback"
      @ssl_ca_file = options[:ssl_ca_file]
      @auth_host = "oauth.live.com"
      @authorize_path = "/authorize"
      @scope = "wl.basic"
      @request_token_path = "/token"
      @contacts_host = "apis.live.net"
      @contacts_path = "/v5.0/me/contacts"
    end

    def call env
      @env = env
      if env["PATH_INFO"] == "/contacts/hotmail"  
        redirect_to_hotmail_site
      else
        if env["PATH_INFO"] =~ /^#{@redirect_path}/
          env["omnicontacts.contacts"] = fetch_contacts(env)
        end
        @app.call(env)
      end
    end

    def redirect_uri
      host_url_from_rack_env(@env) + @redirect_path
    end

    private

    def redirect_to_hotmail_site
     [302, {"location" => authorization_url}, []] 
    end

    def fetch_contacts env
      code = query_string_to_map(env["QUERY_STRING"])["code"]
      contacts_from_code(code)
    end

    def contacts_from_code code
      token, token_type = access_token_from_code(code)
      contacts_from_access_token token, token_type
    end

    def contacts_from_access_token token, token_type
      contacts_response = https_connection(@contacts_host).request_get("#{@contacts_path}?access_token=#{token}")
      contacts_from_response contacts_response
    end

    def contacts_from_response response
      raise "Request failed" if response.code != "200"
      json = ActiveSupport::JSON.decode(escape_windows_format(response.body)) 
      result = []
      json["data"].each do |contact|
        result << {:email => contact["name"]} if valid_email? contact["name"]
      end
      result
    end

    def escape_windows_format value
      value.gsub(/[\r\s]/,'')
    end

    def valid_email? value
      /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/.match(value)
    end

  end

end
