require "omnicontacts/parse_utils"
require "omnicontacts/middleware/oauth1"
require "json"

module OmniContacts
  module Importer
    class Yahoo < Middleware::OAuth2
      include ParseUtils

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      def initialize app, client_id, client_secret, options ={}
        super app, client_id, client_secret, options

        @auth_host = 'api.login.yahoo.com'
        @authorize_path = '/oauth2/request_auth'
        @auth_token_path = '/oauth2/get_token'
        @scope = ''

        @contacts_host = 'social.yahooapis.com'
      end

      def fetch_contacts_using_access_token access_token, token_type, opt=nil
        binding.pry
        fetch_current_user(access_token, token_type)
        # contacts_response = https_get(@contacts_host, @contacts_path, {}, contacts_req_headers(access_token, token_type))
        # contacts_from_response contacts_response
      end

      def fetch_current_user access_token, token_type
        self_response = https_get(@contacts_host, @self_path, {}, contacts_req_headers(access_token, token_type))
        binding.pry
        user = current_user self_response
        set_current_user user
      end

      def contacts_req_headers token, token_type
        { "Authorization" => "#{token_type} #{token}" }
      end
    end
  end
end
