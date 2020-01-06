require "omnicontacts/parse_utils"
require "omnicontacts/middleware/oauth2"
require "json"

module OmniContacts
  module Importer
    class Yahoo < Middleware::OAuth2
      include ParseUtils

      attr_reader :auth_host, :authorize_path, :scope, :auth_token_path, :token_type

      def initialize *args
        super *args
        @auth_host = 'api.login.yahoo.com'
        @authorize_path = '/oauth2/request_auth'
        @scope = 'sdct-r'
        @auth_token_path = '/oauth2/get_token'
        @contacts_host = 'social.yahooapis.com'
        @token_type = 'Bearer'
      end

      def fetch_contacts_using_access_token access_token, token_type
        guid = session['xoauth_yahoo_guid']
        fetch_current_user(access_token, guid)
        contacts_path = "/v1/user/#{guid}/contacts"
        contacts_response = https_get(@contacts_host, contacts_path, contacts_req_params, contacts_req_headers(access_token))
        contacts_from_response contacts_response
      end

      def fetch_current_user access_token, guid
        self_path = "/v1/user/#{guid}/profile"
        self_response =  https_get(@contacts_host, self_path, contacts_req_params, contacts_req_headers(access_token))
        user = current_user self_response
        set_current_user user
      end

      private

      def contacts_req_params
        { :format => 'json' }
      end

       def contacts_req_headers token
        { "Authorization" => "#{token_type} #{token}", "Content-Type" => "application/json" }
      end

      def contacts_from_response response_as_json
        response = JSON.parse(response_as_json)
        contacts = []
        return contacts unless response['contacts']['contact']
        response['contacts']['contact'].each do |entry|
          # creating nil fields to keep the fields consistent across other networks
          contact = { :id => nil,
                      :first_name => nil,
                      :last_name => nil,
                      :name => nil,
                      :email => nil,
                      :gender => nil,
                      :birthday => nil,
                      :profile_picture=> nil,
                      :address_1 => nil,
                      :address_2 => nil,
                      :city => nil,
                      :region => nil,
                      :postcode => nil,
                      :relation => nil }
          yahoo_id = nil
          contact[:id] = entry['id'].to_s
          entry['fields'].each do |field|
            case field['type']
            when 'name'
              contact[:first_name] = normalize_name(field['value']['givenName'])
              contact[:last_name] = normalize_name(field['value']['familyName'])
              contact[:name] = full_name(contact[:first_name],contact[:last_name])
            when 'email'
              contact[:email] = field['value'] if field['type'] == 'email'
            when 'yahooid'
              yahoo_id = field['value']
            when 'address'
              value = field['value']
              contact[:address_1] = street = value['street']
              if street.index("\n")
                parts = street.split("\n")
                contact[:address_1] = parts.first
                contact[:address_2] = parts[1..-1].join(', ')
              end
              contact[:city] = value['city']
              contact[:region] = value['stateOrProvince']
              contact[:postcode] = value['postalCode']
            when 'birthday'
              contact[:birthday] = birthday_format(field['value']['month'], field['value']['day'],field['value']['year'])
            end
            contact[:first_name], contact[:last_name], contact[:name] = email_to_name(contact[:email]) if contact[:name].nil? && contact[:email]
            # contact[:first_name], contact[:last_name], contact[:name] = email_to_name(yahoo_id) if (yahoo_id && contact[:name].nil? && contact[:email].nil?)

            if yahoo_id
              contact[:profile_picture] = image_url(yahoo_id)
            else
              contact[:profile_picture] = image_url_from_email(contact[:email])
            end
          end
          contacts << contact if contact[:name]
        end
        contacts.uniq! {|c| c[:email] || c[:profile_picture] || c[:name]}
        contacts
      end

      def image_url yahoo_id
        return 'https://img.msg.yahoo.com/avatar.php?yids=' + yahoo_id if yahoo_id
      end

      def parse_email(emails)
        return nil if emails.nil?
        email = nil
        if emails.is_a?(Hash)
          if emails.has_key?("primary")
            email = emails['handle']
          end
        elsif emails.is_a?(Array)
          emails.each do |e|
            if e.has_key?('primary') && e['primary']
              email = e['handle']
              break
            end
          end
        end
        email
      end

      def birthday dob
        return nil if dob.nil?
        birthday = dob.split('/')
        return birthday_format(birthday[0], birthday[1], birthday[3]) if birthday.size == 3
        return birthday_format(birthday[0], birthday[1], nil) if birthday.size == 2

      end

      def gender g
        return "female" if g == "F"
        return "male" if g == "M"
      end

      def my_image img
        return nil if img.nil?
        return img['imageUrl']
      end

      def current_user me
        return nil if me.nil?
        me = JSON.parse(me)
        me = me['profile']
        email = parse_email(me['emails'])
        user = {:id => me["guid"], :email => email, :name => full_name(me['givenName'],me['familyName']), :first_name => normalize_name(me['givenName']),
                :last_name => normalize_name(me['familyName']), :gender => gender(me['gender']), :birthday => birthday(me['birthdate']),
                :profile_picture => my_image(me['image'])
               }
        user
      end
    end
  end
end
