require "omnicontacts/http_utils"
require "base64"

# This module represent a OAuth 1.0 Client.
#
# Classes including the module must implement
# the following methods:
# * auth_host ->  the host of the authorization server
# * auth_token_path -> the path to query to obtain a request token
# * consumer_key -> the registered consumer key of the client
# * consumer_secret -> the registered consumer secret of the client
# * callback -> the callback to include during the redirection step
# * auth_path -> the path on the authorization server to redirect the user to
# * access_token_path -> the path to query in order to obtain the access token
module OmniContacts
  module Authorization
    module OAuth1
      include HTTPUtils

      OAUTH_VERSION = "1.0"

      # Obtain an authorization token from the server.
      # The token is returned in an array along with the relative authorization token secret.
      def fetch_authorization_token
        request_token_response = https_post(auth_host, auth_token_path, request_token_req_params)
        values_from_query_string(request_token_response, ["oauth_token", "oauth_token_secret"])
      end

      private

      def request_token_req_params
        {
          :oauth_consumer_key => consumer_key,
          :oauth_nonce => encode(random_string),
          :oauth_signature_method => "PLAINTEXT",
          :oauth_signature => encode(consumer_secret + "&"),
          :oauth_timestamp => timestamp,
          :oauth_version => OAUTH_VERSION,
          :oauth_callback => callback
        }
      end

      def random_string
        (0...50).map { ('a'..'z').to_a[rand(26)] }.join
      end

      def timestamp
        Time.now.to_i.to_s
      end

      def values_from_query_string query_string, keys_to_extract
        map = query_string_to_map(query_string)
        keys_to_extract.collect do |key|
          if map.has_key?(key)
            map[key]
          else
            raise "No value found for #{key} in #{query_string}"
          end
        end
      end

      public

      # Returns the url the user has to be redirected to do in order grant permission to the client application.
      def authorization_url auth_token
        "https://" + auth_host + auth_path + "?oauth_token=" + auth_token
      end

      # Fetches the access token from the authorization server.
      # The method expects the authorization token, the authorization token secret and the authorization verifier.
      # The result comprises the access token, the access token secret and a list of additional fields extracted from the server's response.
      # The list of additional fields to extract is specified as last parameter
      def fetch_access_token auth_token, auth_token_secret, auth_verifier, additional_fields_to_extract = []
        access_token_resp = https_post(auth_host, access_token_path, access_token_req_params(auth_token, auth_token_secret, auth_verifier))
        values_from_query_string(access_token_resp, (["oauth_token", "oauth_token_secret"] + additional_fields_to_extract))
      end

      private

      def access_token_req_params auth_token, auth_token_secret, auth_verifier
        {
          :oauth_consumer_key => consumer_key,
          :oauth_nonce => encode(random_string),
          :oauth_signature_method => "PLAINTEXT",
          :oauth_signature => encode(consumer_secret + "&" + auth_token_secret),
          :oauth_version => OAUTH_VERSION,
          :oauth_timestamp => timestamp,
          :oauth_token => auth_token,
          :oauth_verifier => auth_verifier
        }
      end

      public

      # Calculates a signature using HMAC-SHA1 according to the OAuth 1.0 specifications.
      # 
      # The base string is given is a RFC 3986 encoded concatenation of:
      # * Uppercase HTTP method
      # * An '&'
      # * A url without any parameters
      # * An '&'
      # * All parameters to use in the request encoded themselves and sorted by key.
      #
      # The signature key is given by the concatenation of:
      # * RFC 3986 encoded consumer secret
      # * An  '&'
      # * RFC 3986 encoded token secret
      def oauth_signature method, url, params, secret
        encoded_method = encode(method.upcase)
        encoded_url = encode(url)
        # params must be in alphabetical order
        encoded_params = encode(to_query_string(params.sort))
        base_string = encoded_method + '&' + encoded_url + '&' + encoded_params
        key = encode(consumer_secret) + '&' + secret
        hmac_sha1 = OpenSSL::HMAC.digest('sha1', key, base_string)
        # base64 encode results must be stripped
        encode(Base64.encode64(hmac_sha1).strip)
      end

    end
  end
end
