require "omnicontacts/parse_utils"
require "omnicontacts/middleware/oauth2"
require "json"

module OmniContacts
  module Importer
    class Facebook < Middleware::OAuth2
      include ParseUtils

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      PAGE_SIZE = 1000

      def initialize app, client_id, client_secret, options ={}
        super app, client_id, client_secret, options
        @auth_host = 'graph.facebook.com'
        @authorize_path = '/v2.3/oauth/authorize'
        @scope = 'email,user_relationships,user_birthday'
        @auth_token_path = '/v2.3/oauth/access_token'
        @contacts_host = 'graph.facebook.com'
        @friends_path = '/v2.3/me/friends'
        @taggable_friends_path = '/v2.3/me/taggable_friends'
        @family_path = '/v2.3/me/family'
        @self_path = '/v2.3/me'
        @window_params = options[:window_params] || {}
      end

      def authorize_url_params
        to_query_string({
                          :client_id => client_id,
                          :scope => encode(scope),
                          :response_type => "code",
                          :access_type => "online",
                          :approval_prompt => "auto",
                          :redirect_uri => encode(redirect_uri)
                        }.merge(@window_params))
      end

      def fetch_contacts_using_access_token access_token, access_token_secret
        self_response = fetch_current_user access_token
        user = current_user self_response
        set_current_user user
        spouse_id = extract_spouse_id self_response
        spouse_response = nil
        if spouse_id
          spouse_path = "/#{spouse_id}"
          spouse_response = https_get(@contacts_host, spouse_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,picture'})
        end
        family_response = https_get(@contacts_host, @family_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,picture,relationship'})

        friends_response = https_get(@contacts_host, @friends_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,picture', :limit => PAGE_SIZE})
        friends_response = iterate_pages(friends_response, access_token)
        friends_info = JSON.parse(friends_response)

        total_friends = friends_info.andand['summary'].andand['total_count'] || PAGE_SIZE
        picture_urls = friends_info.andand['data'].map { |info| info.andand['picture'].andand['data'].andand['url'] }.to_set || [].to_set

        taggable_friends_response = https_get(@contacts_host, @taggable_friends_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,picture', :limit => total_friends})
        taggable_info = JSON.parse(taggable_friends_response)
        taggable_unique = taggable_info['data'].reject { |info| picture_urls.include? info['picture']['data']['url'] }
        combined_friends = friends_info['data'] + taggable_unique
        taggable_info['data'] = combined_friends
        new_taggable_friends_response = taggable_info.to_json

        contacts_from_response(spouse_response, family_response, new_taggable_friends_response)
      end

      def fetch_current_user access_token
        self_response = https_get(@contacts_host, @self_path, {:access_token => access_token, :fields => 'first_name,last_name,name,id,gender,birthday,picture,relationship_status,significant_other,email'})
        self_response = JSON.parse(self_response) if self_response
        self_response
      end

      private

      def extract_spouse_id response
        return nil if response.nil?
        id = nil
        if response['significant_other'] && response['relationship_status'] == 'Married'
          id = response['significant_other']['id']
        end
        id
      end

      def iterate_pages(response, access_token)
        begin
          @access_token = access_token
          current_response = JSON.parse(response)
          data = current_response['data']
          while current_response['paging']['next']
            next_page = JSON.parse(next_page_call(current_response['paging']['next']))
            data += next_page['data']
            current_response = next_page
          end
          current_response['data'] = data
          return current_response.to_json
        rescue
          return response
        end
      end

      def next_page_call(page_url)
        my_token.get(page_url, {}).body
      end

      def my_client
        @my_client ||= OAuth2::Client.new(client_id, {})
      end

      def my_token
        @my_token ||= OAuth2::AccessToken.new(my_client, @access_token)
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
        contact[:birthday] = birthday(contact_info['birthday'])
        contact[:profile_picture] = contact_info['picture']['data']['url'];
        contact[:relation] = contact_info['relationship']
        contact
      end

      def image_url fb_id
        return "https://graph.facebook.com/" + fb_id + "/picture" if fb_id
      end

      def escape_windows_format value
        value.gsub(/[\r\s]/, '')
      end

      def birthday dob
        return nil if dob.nil?
        birthday = dob.split('/')
        return birthday_format(birthday[0],birthday[1],birthday[2])
      end

      def current_user me
        return nil if me.nil?
        user = {:id => me['id'], :email => me['email'],
                :name => me['name'], :first_name => normalize_name(me['first_name']),
                :last_name => normalize_name(me['last_name']), :birthday => birthday(me['birthday']),
                :gender => me['gender'], :profile_picture => image_url(me['id'])
        }
        user
      end

    end
  end
end
