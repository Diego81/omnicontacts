require "omnicontacts/middleware/oauth1"
require "json"

module OmniContacts
  module Importer
    class Yahoo < Middleware::OAuth1

      attr_reader :auth_host, :auth_token_path, :auth_path, :access_token_path

      def initialize *args
        super *args
        @auth_host = 'api.login.yahoo.com'
        @auth_token_path = '/oauth/v2/get_request_token'
        @auth_path = '/oauth/v2/request_auth'
        @access_token_path = '/oauth/v2/get_token'
        @contacts_host = 'social.yahooapis.com'
      end

      def fetch_contacts_from_token_and_verifier auth_token, auth_token_secret, auth_verifier
        (access_token, access_token_secret, guid) = fetch_access_token(auth_token, auth_token_secret, auth_verifier, ['xoauth_yahoo_guid'])
        contacts_path = "/v1/user/#{guid}/contacts"
        contacts_response = http_get(@contacts_host, contacts_path, contacts_req_params(access_token, access_token_secret, contacts_path))
        contacts_from_response contacts_response
      end

      private

      def contacts_req_params access_token, access_token_secret, contacts_path
        params = {
            :format => 'json',
            :oauth_consumer_key => consumer_key,
            :oauth_nonce => encode(random_string),
            :oauth_signature_method => 'HMAC-SHA1',
            :oauth_timestamp => timestamp,
            :oauth_token => access_token,
            :oauth_version => OmniContacts::Authorization::OAuth1::OAUTH_VERSION,
            :view => 'compact'
        }
        contacts_url = "http://#{@contacts_host}#{contacts_path}"
        params['oauth_signature'] = oauth_signature('GET', contacts_url, params, access_token_secret)
        params
      end

      def contacts_from_response response_as_json
        response = JSON.parse(response_as_json)
        contacts = []
        return contacts unless response['contacts']['contact']
        response['contacts']['contact'].each do |entry|
          # creating nil fields to keep the fields consistent across other networks
          contact = {:id => nil, :first_name => nil, :last_name => nil, :name => nil, :email => nil, :gender => nil, :birthday => nil, :image_source => nil, :relation => nil}
          yahoo_id = nil
          contact[:id] = entry['id'].to_s
          entry['fields'].each do |field|
            if field['type'] == 'name'
              contact[:first_name] = normalize_name(field['value']['givenName'])
              contact[:last_name] = normalize_name(field['value']['familyName'])
              contact[:name] = full_name(contact[:first_name],contact[:last_name])
            end
            contact[:email] = field['value'] if field['type'] == 'email'

            if field['type'] == 'yahooid'
              yahoo_id = field['value']
            end

            contact[:first_name], contact[:last_name], contact[:name] = email_to_name(contact[:email]) if contact[:name].nil? && contact[:email]
            # contact[:first_name], contact[:last_name], contact[:name] = email_to_name(yahoo_id) if (yahoo_id && contact[:name].nil? && contact[:email].nil?)

            if field['type'] == 'birthday'
              contact[:birthday] = birthday_format(field['value']['month'], field['value']['day'],field['value']['year'])
            end
          end
          contacts << contact if contact[:name]
        end
        contacts.uniq! {|c| c[:email] || c[:name]}
        contacts
      end

    end
  end
end
