require "omnicontacts/middleware/oauth2"
require "rexml/document"

module OmniContacts
  module Importer
    class Gmail < Middleware::OAuth2

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      def initialize *args
        super *args
        @auth_host = "accounts.google.com"
        @authorize_path = "/o/oauth2/auth"
        @auth_token_path = "/o/oauth2/token"
        @scope = "https://www.google.com/m8/feeds"
        @contacts_host = "www.google.com"
        @contacts_path = "/m8/feeds/contacts/default/full"
        @max_results =  (args[3] && args[3][:max_results]) || 100
      end

      def fetch_contacts_using_access_token access_token, token_type
        contacts_response = https_get(@contacts_host, @contacts_path, contacts_req_params, contacts_req_headers(access_token, token_type))
        parse_contacts contacts_response
      end

      private

      def contacts_req_params
        {"max-results" => @max_results.to_s}
      end

      def contacts_req_headers token, token_type
        {"GData-Version" => "3.0", "Authorization" => "#{token_type} #{token}"}
      end

      def parse_contacts contacts_as_xml
        xml = REXML::Document.new(contacts_as_xml)
        contacts = []
        xml.elements.each('//entry') do |entry|
          gd_email = entry.elements['gd:email']
          if gd_email
            contact = {:email => gd_email.attributes['address']}
            gd_name = entry.elements['gd:name']
            if gd_name
              gd_full_name = gd_name.elements['gd:fullName']
              contact[:name] = gd_full_name.text if gd_full_name
            end
            contacts << contact
          end
        end
        contacts
      end

    end
  end
end
