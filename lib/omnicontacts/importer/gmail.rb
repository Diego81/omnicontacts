require "omnicontacts/parse_utils"
require "omnicontacts/middleware/oauth2"

module OmniContacts
  module Importer
    class Gmail < Middleware::OAuth2
      include ParseUtils

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      def initialize *args
        super *args
        @auth_host = "accounts.google.com"
        @authorize_path = "/o/oauth2/auth"
        @auth_token_path = "/o/oauth2/token"
        @scope = "https://www.google.com/m8/feeds https://www.googleapis.com/auth/userinfo#email https://www.googleapis.com/auth/userinfo.profile"
        @contacts_host = "www.google.com"
        @contacts_path = "/m8/feeds/contacts/default/full"
        @max_results =  (args[3] && args[3][:max_results]) || 100
        @self_host = "www.googleapis.com"
        @profile_path = "/oauth2/v1/userinfo"
      end

      def fetch_contacts_using_access_token access_token, token_type
        fetch_current_user(access_token, token_type)
        contacts_response = https_get(@contacts_host, @contacts_path, contacts_req_params, contacts_req_headers(access_token, token_type))
        contacts_from_response contacts_response
      end

      def fetch_current_user access_token, token_type
        self_response = https_get(@self_host, @profile_path, contacts_req_params, contacts_req_headers(access_token, token_type))
        user = current_user(self_response, access_token, token_type)
        set_current_user user
      end

      private

      def contacts_req_params
        {'max-results' => @max_results.to_s, 'alt' => 'json'}
      end

      def contacts_req_headers token, token_type
        {"GData-Version" => "3.0", "Authorization" => "#{token_type} #{token}"}
      end

      def contacts_from_response response_as_json
        response = JSON.parse(response_as_json)
        return [] if response['feed'].nil? || response['feed']['entry'].nil?
        contacts = []
        return contacts if response.nil?
        response['feed']['entry'].each do |entry|
          # creating nil fields to keep the fields consistent across other networks

          contact = { :id => nil,
                      :first_name => nil,
                      :last_name => nil,
                      :name => nil,
                      :email => nil,
                      :gender => nil,
                      :birthday => nil,
                      :profile_picture=> nil,
                      :relation => nil,
                      :address_1 => nil,
                      :address_2 => nil,
                      :city => nil,
                      :region => nil,
                      :country => nil,
                      :postcode => nil,
                      :phone_number => nil
          }
          contact[:id] = entry['id']['$t'] if entry['id']
          if entry['gd$name']
            gd_name = entry['gd$name']
            contact[:first_name] = normalize_name(entry['gd$name']['gd$givenName']['$t']) if gd_name['gd$givenName']
            contact[:last_name] = normalize_name(entry['gd$name']['gd$familyName']['$t']) if gd_name['gd$familyName']
            contact[:name] = normalize_name(entry['gd$name']['gd$fullName']['$t']) if gd_name['gd$fullName']
            contact[:name] = full_name(contact[:first_name],contact[:last_name]) if contact[:name].nil?
          end

          contact[:email] = entry['gd$email'][0]['address'] if entry['gd$email']
          contact[:first_name], contact[:last_name], contact[:name] = email_to_name(contact[:name]) if !contact[:name].nil? && contact[:name].include?('@')
          contact[:first_name], contact[:last_name], contact[:name] = email_to_name(contact[:email]) if contact[:name].nil? && contact[:email]
          #format - year-month-date
          contact[:birthday] = birthday(entry['gContact$birthday']['when'])  if entry['gContact$birthday']

          # value is either "male" or "female"
          contact[:gender] = entry['gContact$gender']['value']  if entry['gContact$gender']

          if entry['gContact$relation']
            if entry['gContact$relation'].is_a?(Hash)
              contact[:relation] = entry['gContact$relation']['rel']
            elsif entry['gContact$relation'].is_a?(Array)
              contact[:relation] = entry['gContact$relation'].first['rel']
            end
          end

          address = entry['gd$structuredPostalAddress'][0] if entry['gd$structuredPostalAddress']
          if address
            contact[:address_1] = address['gd$street']['$t'] if address['gd$street']
            contact[:address_1] = address['gd$formattedAddress']['$t'] if contact[:address_1].nil? && address['gd$formattedAddress']
            if contact[:address_1].index("\n")
              parts = contact[:address_1].split("\n")
              contact[:address_1] = parts.first
              # this may contain city/state/zip if user jammed it all into one string.... :-(
              contact[:address_2] = parts[1..-1].join(', ')
            end
            contact[:city] = address['gd$city']['$t'] if address['gd$city']
            contact[:region] = address['gd$region']['$t'] if address['gd$region'] # like state or province
            contact[:country] = address['gd$country']['code'] if address['gd$country']
            contact[:postcode] = address['gd$postcode']['$t'] if address['gd$postcode']
          end
          contact[:phone_number] =  entry["gd$phoneNumber"][0]['$t'] if entry["gd$phoneNumber"]

          if entry['gContact$website'] && entry['gContact$website'][0]["rel"] == "profile"
            contact[:id] = contact_id(entry['gContact$website'][0]["href"])
            contact[:profile_picture] = image_url(contact[:id])
          else
            contact[:profile_picture] = image_url_from_email(contact[:email])
          end

          contacts << contact if contact[:name]
        end
        contacts.uniq! {|c| c[:email] || c[:profile_picture] || c[:name]}
        contacts
      end

      def image_url gmail_id
        return "https://profiles.google.com/s2/photos/profile/" + gmail_id if gmail_id
      end

      def current_user me, access_token, token_type
        return nil if me.nil?
        me = JSON.parse(me)
        user = {:id => me['id'], :email => me['email'], :name => me['name'], :first_name => me['given_name'],
                :last_name => me['family_name'], :gender => me['gender'], :birthday => birthday(me['birthday']), :profile_picture => image_url(me['id']),
                :access_token => access_token, :token_type => token_type
        }
        user
      end

      def birthday dob
        return nil if dob.nil?
        birthday = dob.split('-')
        return birthday_format(birthday[2], birthday[3], nil) if birthday.size == 4
        return birthday_format(birthday[1], birthday[2], birthday[0]) if birthday.size == 3
      end

      def contact_id(profile_url)
        id = (profile_url.present?) ? File.basename(profile_url) : nil
        id
      end

    end
  end
end
