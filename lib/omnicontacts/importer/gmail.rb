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
        parse_contacts contacts_response, access_token, token_type
      end

      private

      def contacts_req_params
        {"max-results" => @max_results.to_s}
      end

      def contacts_req_headers token, token_type
        {"GData-Version" => "3.0", "Authorization" => "#{token_type} #{token}"}
      end

      def parse_contacts contacts_as_xml, access_token, token_type
        xml = REXML::Document.new(contacts_as_xml)
        contacts = []
        contacts << {:access_token => access_token}

        xml.elements.each('//entry') do |entry|
          gd_email = entry.elements['gd:email']
          if gd_email
            contact = {:email => gd_email.attributes['address']}
            gd_name = entry.elements['gd:name']
            if gd_name
              gd_full_name = gd_name.elements['gd:fullName']
              contact[:name] = gd_full_name.text if gd_full_name
            end

            gd_avatar = entry.elements['link[@type="image/*"]']
            contact[:avatar_url] = gd_avatar ? gd_avatar.attribute('href').to_s : nil
            
            ### Use the below if you want to return the avatar file itself.
            # if gd_avatar
            #   avatar_url_parsed = URI.parse(gd_avatar.attribute('href').to_s)
            #   avatar_host = avatar_url_parsed.host
            #   avatar_path = avatar_url_parsed.path
            #   avatar_response = https_get(avatar_host, avatar_path, contacts_req_params, contacts_req_headers(access_token, token_type))
              # contact[:avatar] = avatar_response.body if avatar_response.status_code == 200
            # end
            
            contacts << contact
          end
        end
        contacts
      end

    end
  end
end
