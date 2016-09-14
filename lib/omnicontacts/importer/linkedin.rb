require "omnicontacts/parse_utils"
require "omnicontacts/middleware/oauth2"

module OmniContacts
  module Importer
    class Linkedin < Middleware::OAuth2
      include ParseUtils

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope, :state

      def initialize *args
        super *args
        @auth_host = "www.linkedin.com"
        @authorize_path = "/uas/oauth2/authorization"
        @auth_token_path = "/uas/oauth2/accessToken"
        @scope = (args[3] && args[3][:scope]) || "r_network"
        @contacts_host = "api.linkedin.com"
        @contacts_path = "/v1/people/~/connections:(id,first-name,last-name,picture-url)"
        @self_host = "www.linkedin.com"
        @profile_path = "/oauth2/v1/userinfo"
        @state = (args[3] && args[3][:state])
      end

      def fetch_contacts_using_access_token access_token, token_type
        token_type = "Bearer" if token_type.nil?
        contacts_response = https_get(@contacts_host, @contacts_path, contacts_req_params, contacts_req_headers(access_token, token_type))
        contacts_from_response contacts_response
      end

      private

      def contacts_req_params
        {'format' => 'json'}
      end

      def contacts_req_headers token, token_type
        {"Authorization" => "#{token_type} #{token}"}
      end

      def contacts_from_response response_as_json
        response = JSON.parse(response_as_json)
        return [] if response['values'].nil?
        contacts = []
        return contacts if response.nil?
        response['values'].map do |entry|
          {
           id: entry['id'],
            first_name: normalize_name(entry['firstName']),
            last_name: normalize_name(entry['lastName']),
            name: full_name(entry['firstName'],entry['lastName']),
            profile_picture: entry['pictureUrl']
          }
        end
      end

      def authorize_url_params
        # merge state param required by LinkedIn
        _params = super
        _params += "&" + to_query_string(state: @state)
      end
    end
  end
end
