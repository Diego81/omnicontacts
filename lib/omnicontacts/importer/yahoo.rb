require "omnicontacts/middleware/oauth1"
require "json"

module OmniContacts
  module Importer
    class Yahoo < Middleware::OAuth1

      attr_reader :auth_host, :auth_token_path, :auth_path, :access_token_path

      def initialize *args
        super *args
        @auth_host = "api.login.yahoo.com"
        @auth_token_path = "/oauth/v2/get_request_token"
        @auth_path = "/oauth/v2/request_auth"
        @access_token_path = "/oauth/v2/get_token"
        @contacts_host = "social.yahooapis.com"
      end

      def fetch_contacts_from_token_and_verifier auth_token, auth_token_secret, auth_verifier
        (access_token, access_token_secret, guid) = fetch_access_token(auth_token, auth_token_secret, auth_verifier, ["xoauth_yahoo_guid"])
        contacts_path = "/v1/user/#{guid}/contacts"
        contacts_response = http_get(@contacts_host, contacts_path, contacts_req_params(access_token, access_token_secret, contacts_path))
        contacts_from_response contacts_response
      end

      private

      def contacts_req_params access_token, access_token_secret, contacts_path
        params = {
          :format => "json",
          :oauth_consumer_key => consumer_key,
          :oauth_nonce => encode(random_string),
          :oauth_signature_method => "HMAC-SHA1",
          :oauth_timestamp => timestamp,
          :oauth_token => access_token,
          :oauth_version => OmniContacts::Authorization::OAuth1::OAUTH_VERSION,
          :view => "compact"
        }
        contacts_url = "http://#{@contacts_host}#{contacts_path}"
        params["oauth_signature"] = oauth_signature("GET", contacts_url, params, access_token_secret)
        params
      end

      def contacts_from_response contacts_as_json
        json = JSON.parse(contacts_as_json)
        result = []
        return result unless json["contacts"]["contact"]
        json["contacts"]["contact"].each do |entry|
          contact = {}
          entry["fields"].each do |field|
            contact[:email] = field["value"] if field["type"] == "email"
            if field["type"] == "name"
              name = field["value"]["givenName"]
              surname = field["value"]["familyName"]
              contact[:name] = "#{name} #{surname}" if name && surname
            end
          end
          result << contact if contact[:email]
        end
        result
      end

    end
  end
end
