require "omnicontacts/oauth2"

module OmniContacts
  class Gmail < OmniContacts::OAuth2

    attr_reader :client_id, :client_secret, :ssl_ca_file, :auth_host, :authorize_path, :request_token_path, :scope

    def initialize app, client_id, client_secret, options ={}
      @app = app
      @client_id = client_id
      @client_secret = client_secret
      @redirect_path = options[:redirect_path] || "/contacts/gmail/callback"
      @ssl_ca_file = options[:ssl_ca_file]
      @auth_host = "accounts.google.com"
      @authorize_path = "/o/oauth2/auth"
      @request_token_path = "/o/oauth2/token"
      @scope = "https://www.google.com/m8/feeds"
      @contacts_host = "www.google.com"
      @contacts_path = "/m8/feeds/contacts/default/full?max-results=1000"
    end

    def call env
      @env = env
      if env["PATH_INFO"] == "/contacts/gmail"
        redirect_to_google_site
      else
        puts "redirect path is " + @redirect_path
        if env["PATH_INFO"] =~ /^#{@redirect_path}/
          env["omnicontacts.emails"] = fetch_contacts
        end
        @app.call(env)
      end
    end

    def redirect_uri
      host_url_from_rack_env(@env) + @redirect_path
    end

    private

    def redirect_to_google_site
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

    def contacts_from_access_token token, token_type
      contacts_response = https_connection(@contacts_host).request_get(@contacts_path, contacts_req_headers(token, token_type))    
      contacts_from_response contacts_response
    end

    def contacts_req_headers token, token_type
      {"GData-Version" => "3.0",  "Authorization" => "#{token_type} #{token}"}  
    end

    # TODO: raise an exception in case of error. The exception must include the reason for the failure
    def contacts_from_response response
      raise "Request failed" if response.code != "200"
      parse_contacts_from_xml(response.body)
    end

    def parse_contacts_from_xml contacts_as_xml
      xml = REXML::Document.new(contacts_as_xml)
      contacts = []
      xml.elements.each('//entry') do |entry|
        gd_email = entry.elements['gd:email']
        contacts << gd_email.attributes['address'] if gd_email
      end
      contacts 
    end

  end

end
