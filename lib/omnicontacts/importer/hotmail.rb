require "omnicontacts/middleware/oauth2"
require "json"

module OmniContacts
  module Importer
    class Hotmail < Middleware::OAuth2

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      def initialize *args
        super *args
        @auth_host = "oauth.live.com"
        @authorize_path = "/authorize"
        @scope = "wl.basic"
        @auth_token_path = "/token"
        @contacts_host = "apis.live.net"
        @contacts_path = "/v5.0/me/contacts"
      end

      def fetch_contacts_using_access_token access_token, access_token_secret
        contacts_response = https_get(@contacts_host, @contacts_path, :access_token => access_token)
        contacts_from_response contacts_response
      end

      private

      def contacts_from_response contacts_as_json
        json = JSON.parse(escape_windows_format(contacts_as_json))
        result = []
        json["data"].each do |contact|
          result << {:email => contact["name"]} if valid_email? contact["name"]
        end
        result
      end

      def escape_windows_format value
        value.gsub(/[\r\s]/, '')
      end

      def valid_email? value
        /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/.match(value)
      end

    end
  end
end
