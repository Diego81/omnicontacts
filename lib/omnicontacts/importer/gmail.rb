require "omnicontacts/middleware/oauth2"
require "rexml/document"

module OmniContacts
  class Gmail < OmniContacts::OAuth2Middleware

    attr_reader :client_id, :client_secret, :ssl_ca_file, :auth_host, :authorize_path, :request_token_path, :scope, :listening_path

    def initialize args*
      super args*
      @redirect_path ||= "/contacts/gmail/callback"
      @auth_host = "accounts.google.com"
      @authorize_path = "/o/oauth2/auth"
      @request_token_path = "/o/oauth2/token"
      @scope = "https://www.google.com/m8/feeds"
      @contacts_host = "www.google.com"
      @contacts_path = "/m8/feeds/contacts/default/full?max-results=1000"
      @listening_path = "/contacts/gmail"
    end

    def contacts_from_access_token token, token_type
      contacts_response = https_connection(@contacts_host).request_get(@contacts_path, contacts_req_headers(token, token_type))    
      contacts_from_response contacts_response
    end

    private 

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
        if gd_email
          contact = {:email => gd_email.attributes['address']}
          gd_name = entry.elements['gd:name']
          if gd_name
            contact[:name] = gd_name.elements['gd:fullName'].text
          end
          contacts << contact
        end
      end
      contacts 
    end

  end

end
