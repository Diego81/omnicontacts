require "omnicontacts/parse_utils"
require "omnicontacts/middleware/oauth2"

module OmniContacts
  module Importer
    class Slack < Middleware::OAuth2
      include ParseUtils

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      def initialize *args
        super *args
        @auth_host = "slack.com"
        @authorize_path = "/oauth/authorize"
        @auth_token_path = "/api/oauth.access"
        @scope = (args[3] && args[3][:scope]) || "users:read users:read.email"
        @contacts_host = "slack.com"
        @contacts_path = "/api/users.list"
        @max_results =  (args[3] && args[3][:max_results]) || 500
      end

      def fetch_contacts_using_access_token access_token, token_type
        contacts_response = https_get(@contacts_host, @contacts_path, contacts_req_params(access_token))
        contacts_from_response(contacts_response)
      end

      private

      def contacts_req_params access_token
        {'token' => access_token}
      end

      def contacts_from_response(response_as_json)
        response = JSON.parse(response_as_json)
        contacts = []
        response["members"].each do |member|
          contacts << {
            :id => member["id"],
            :profile_picture => member["profile"]["image_original"],
            :first_name => member["profile"]["first_name"],
            :last_name => member["profile"]["last_name"],
            :name => member["profile"]["real_name"],
            :email => member["profile"]["email"],
            :emails => [
              {
                :name => member["profile"]["real_name"],
                :email => member["profile"]["email"]
              }
            ]
          }
        end

        contacts
      end

    end
  end
end
