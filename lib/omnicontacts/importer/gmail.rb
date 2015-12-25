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
        @scope = (args[3] && args[3][:scope]) || "https://www.googleapis.com/auth/contacts.readonly https://www.googleapis.com/auth/userinfo#email https://www.googleapis.com/auth/userinfo.profile"
        @contacts_host = "www.google.com"
        @contacts_path = "/m8/feeds/contacts/default/full"
        @max_results =  (args[3] && args[3][:max_results]) || 100
        @self_host = "www.googleapis.com"
        @profile_path = "/oauth2/v3/userinfo"
      end

      def fetch_contacts_using_access_token access_token, token_type
        fetch_current_user(access_token, token_type)
        contacts_response = https_get(@contacts_host, @contacts_path, contacts_req_params, contacts_req_headers(access_token, token_type))
        contacts_from_response(contacts_response, access_token)
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

      def contacts_from_response(response_as_json, access_token)
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
                      :emails => nil,
                      :gender => nil,
                      :birthday => nil,
                      :profile_picture=> nil,
                      :relation => nil,
                      :addresses => nil,
                      :phone_numbers => nil,
                      :dates => nil,
                      :company => nil,
                      :position => nil
          }
          contact[:id] = entry['id']['$t'] if entry['id']
          if entry['gd$name']
            gd_name = entry['gd$name']
            contact[:first_name] = normalize_name(entry['gd$name']['gd$givenName']['$t']) if gd_name['gd$givenName']
            contact[:last_name] = normalize_name(entry['gd$name']['gd$familyName']['$t']) if gd_name['gd$familyName']
            contact[:name] = normalize_name(entry['gd$name']['gd$fullName']['$t']) if gd_name['gd$fullName']
            contact[:name] = full_name(contact[:first_name],contact[:last_name]) if contact[:name].nil?
          end

          contact[:emails] = []
          entry['gd$email'].each do |email|
            if email['rel']
              split_index = email['rel'].index('#')
              contact[:emails] << {:name => email['rel'][split_index + 1, email['rel'].length - 1], :email => email['address']}
            elsif email['label']
              contact[:emails] << {:name => email['label'], :email => email['address']}
            end
          end if entry['gd$email']

          # Support older versions of the gem by keeping singular entries around
          contact[:email] = contact[:emails][0][:email] if contact[:emails][0]
          contact[:first_name], contact[:last_name], contact[:name] = email_to_name(contact[:name]) if !contact[:name].nil? && contact[:name].include?('@')
          contact[:first_name], contact[:last_name], contact[:name] = email_to_name(contact[:emails][0][:email]) if (contact[:name].nil? && contact[:emails][0] && contact[:emails][0][:email])
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

          contact[:addresses] = []
          entry['gd$structuredPostalAddress'].each do |address|
            if address['rel']
              split_index = address['rel'].index('#')
              new_address = {:name => address['rel'][split_index + 1, address['rel'].length - 1]}
            elsif address['label']
              new_address = {:name => address['label']}
            end

            new_address[:address_1] = address['gd$street']['$t'] if address['gd$street']
            new_address[:address_1] = address['gd$formattedAddress']['$t'] if new_address[:address_1].nil? && address['gd$formattedAddress']
            if new_address[:address_1].index("\n")
              parts = new_address[:address_1].split("\n")
              new_address[:address_1] = parts.first
              # this may contain city/state/zip if user jammed it all into one string.... :-(
              new_address[:address_2] = parts[1..-1].join(', ')
            end
            new_address[:city] = address['gd$city']['$t'] if address['gd$city']
            new_address[:region] = address['gd$region']['$t'] if address['gd$region'] # like state or province
            new_address[:country] = address['gd$country']['code'] if address['gd$country']
            new_address[:postcode] = address['gd$postcode']['$t'] if address['gd$postcode']
            contact[:addresses] << new_address
          end if entry['gd$structuredPostalAddress']

          # Support older versions of the gem by keeping singular entries around
          if contact[:addresses][0]
            contact[:address_1] = contact[:addresses][0][:address_1]
            contact[:address_2] = contact[:addresses][0][:address_2]
            contact[:city] = contact[:addresses][0][:city]
            contact[:region] = contact[:addresses][0][:region]
            contact[:country] = contact[:addresses][0][:country]
            contact[:postcode] = contact[:addresses][0][:postcode]
          end

          contact[:phone_numbers] = []
          entry['gd$phoneNumber'].each do |phone_number|
            if phone_number['rel']
              split_index = phone_number['rel'].index('#')
              contact[:phone_numbers] << {:name => phone_number['rel'][split_index + 1, phone_number['rel'].length - 1], :number => phone_number['$t']}
            elsif phone_number['label']
              contact[:phone_numbers] << {:name => phone_number['label'], :number => phone_number['$t']}
            end
          end if entry['gd$phoneNumber']

          # Support older versions of the gem by keeping singular entries around
          contact[:phone_number] = contact[:phone_numbers][0][:number] if contact[:phone_numbers][0]

          if entry["link"] && entry["link"].is_a?(Array)
            entry["link"].each do |link|
              if link["type"] == 'image/*' && link["gd$etag"]
                contact[:profile_picture] = link["href"] + "?&access_token=" + access_token
                break
              end
            end
          end

          if entry['gContact$event']
            contact[:dates] = []
            entry['gContact$event'].each do |event|
              if event['rel']
                contact[:dates] << {:name => event['rel'], :date => birthday(event['gd$when']['startTime'])}
              elsif event['label']
                contact[:dates] << {:name => event['label'], :date => birthday(event['gd$when']['startTime'])}
              end
            end
          end

          if entry['gd$organization']
            contact[:company] = entry['gd$organization'][0]['gd$orgName']['$t'] if entry['gd$organization'][0]['gd$orgName']
            contact[:position] = entry['gd$organization'][0]['gd$orgTitle']['$t'] if entry['gd$organization'][0]['gd$orgTitle']
          end

          contacts << contact if contact[:name]
        end
        contacts.uniq! {|c| c[:email] || c[:profile_picture] || c[:name]}
        contacts
      end

      def current_user me, access_token, token_type
        return nil if me.nil?
        me = JSON.parse(me)
        user = {:id => me['id'], :email => me['email'], :name => me['name'], :first_name => me['given_name'],
                :last_name => me['family_name'], :gender => me['gender'], :birthday => birthday(me['birthday']), :profile_picture => me["picture"],
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
