require "omnicontacts/middleware/oauth2"
require "json"

module OmniContacts
  module Importer
    class Facebook < Middleware::OAuth2

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      def initialize *args
        super *args
        @auth_host = 'graph.facebook.com'
        @authorize_path = '/oauth/authorize'
        @scope = 'email,user_relationships,user_birthday,friends_birthday'
        @auth_token_path = '/oauth/access_token'
        @contacts_host = 'graph.facebook.com'
        @friends_path = '/me/friends'
        @family_path = '/me/family'
        @self_path = '/me'
      end

      def fetch_contacts_using_access_token access_token, access_token_secret
        self_response = https_get(@contacts_host, @self_path, :access_token => access_token)
        spouse_id = extract_spouse_id(self_response)
        spouse_response = nil
        if spouse_id
          spouse_path = "/#{spouse_id}"
          spouse_response = https_get(@contacts_host, spouse_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,birthday,picture'})
        end
        family_response = https_get(@contacts_host, @family_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,birthday,picture'})
        friends_response = https_get(@contacts_host, @friends_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,birthday,picture'})
        contacts_from_response(spouse_response, family_response, friends_response)
      end

      private

      def extract_spouse_id self_response
        response = JSON.parse(self_response)
        id = nil
        if response['significant_other'] && response['relationship_status'] == 'Married'
          id = response['significant_other']['id']
        end
        id
      end

      def contacts_from_response(spouse_response, family_response, friends_response)
        contacts = []
        family_ids = Set.new
        if spouse_response
          spouse_contact = create_contact_element(JSON.parse(spouse_response))
          spouse_contact[:relation] = 'spouse'
          contacts << spouse_contact
          family_ids.add(spouse_contact[:id])
        end
        if family_response
          family_response = JSON.parse(family_response)
          family_response['data'].each do |family_contact|
            contacts << create_contact_element(family_contact)
            family_ids.add(family_contact['id'])
          end
        end
        if friends_response
          friends_response = JSON.parse(friends_response)
          friends_response['data'].each do |friends_contact|
            contacts << create_contact_element(friends_contact) unless family_ids.include?(friends_contact['id'])
          end
        end
        contacts
      end

      def create_contact_element contact_info
        # creating nil fields to keep the fields consistent across other networks
        contact = {:id => nil, :first_name => nil, :last_name => nil, :name => nil, :email => nil, :gender => nil, :birthday => nil, :profile_picture=> nil, :relation => nil}
        contact[:id] = contact_info['id']
        contact[:first_name] = normalize_name(contact_info['first_name'])
        contact[:last_name] = normalize_name(contact_info['last_name'])
        contact[:name] = contact_info['name']
        contact[:email] = contact_info['email']
        contact[:gender] = contact_info['gender']
        birthday = contact_info['birthday'].split('/') if contact_info['birthday']
        contact[:birthday] = birthday_format(birthday[0],birthday[1],birthday[2]) if birthday
        contact[:profile_picture] = contact_info['picture']['data']['url'] if contact_info['picture']
        contact[:relation] = contact_info['relationship']
        contact
      end

      def escape_windows_format value
        value.gsub(/[\r\s]/, '')
      end

    end
  end
end
