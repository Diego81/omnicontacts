require "omnicontacts/middleware/oauth2"
require "json"

module OmniContacts
  module Importer
    class Hotmail < OmniContacts::Middleware::OAuth2

      attr_reader :auth_host, :authorize_path, :request_token_path, :scope

      def initialize *args
        super *args
        @redirect_path ||= "/contacts/hotmail/callback"
        @auth_host = "oauth.live.com"
        @authorize_path = "/authorize"
        @scope = "wl.basic"
        @request_token_path = "/token"
        @contacts_host = "apis.live.net"
        @contacts_path = "/v5.0/me/contacts"
      end

      def fetch_contacts_from_authorization_code authorization_code
        (token, token_type) = access_token_from_code(authorization_code)
        contacts_response = https_get(@contacts_host, @contacts_path, :access_token =>token)
        contacts_from_response contacts_response
      end

      def contacts_from_response contacts_as_json
        json = JSON.parse(escape_windows_format(contacts_as_json)) 
        result = []
        json["data"].each do |contact|
          result << {:email => contact["name"]} if valid_email? contact["name"]
        end
        result
      end

      def escape_windows_format value
        value.gsub(/[\r\s]/,'')
      end

      def valid_email? value
        /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/.match(value)
      end

    end
  end
end
