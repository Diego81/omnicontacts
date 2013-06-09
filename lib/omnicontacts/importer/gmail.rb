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
        user = current_user self_response
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
          contact = {:id => nil, :first_name => nil, :last_name => nil, :name => nil, :email => nil, :gender => nil, :birthday => nil, :profile_picture=> nil, :relation => nil}
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
          contact[:image_source] = image_url(contact[:email])
          contact[:relation] = entry['gContact$relation']['rel'] if entry['gContact$relation']

          contacts << contact if contact[:name]
        end
        contacts.uniq! {|c| c[:email] || c[:image_source] || c[:name]}
        contacts
      end

      def current_user me
        return nil if me.nil?
        me = JSON.parse(me)
        user = {:id => me['id'], :email => me['email'], :name => me['name'], :first_name => me['given_name'],
                :last_name => me['family_name'], :gender => me['gender'], :birthday => birthday(me['birthday']), :profile_picture => me['picture']
        }
        user
      end

      def birthday dob
        return nil if dob.nil?
        birthday = dob.split('-')
        return birthday_format(birthday[2], birthday[3], nil) if birthday.size == 4
        return birthday_format(birthday[1], birthday[2], birthday[0]) if birthday.size == 3
      end

      #def profile_image_data path, access_token, token_type
      #  if path
      #    photo_path = path['href'].split('https://www.google.com').second if path['gd$etag']
      #    if photo_path
      #      # need to make a get request to this image_source url to get the actual image of the contact
      #      photo_response = https_get(@contacts_host, photo_path,{}, contacts_req_headers(access_token, token_type))
      #    end
      #  end
      #  photo_response
      #end

    end
  end
end
