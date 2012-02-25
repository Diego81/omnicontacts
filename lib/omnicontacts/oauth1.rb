require "omnicontacts/http_utils"

module OmniContacts

  class OAuth1 
    include HTTPUtils

    OAUTH_VERSION = "1.0"

    def request_token
      request_token_response = https_connection(auth_host).request_post(request_token_path, request_token_req_params)
      values_from_response(request_token_response, ["oauth_token", "oauth_token_secret"])
    end

    private

    def request_token_req_params
      to_query_string({
        :oauth_consumer_key => consumer_key,
        :oauth_nonce => encode(random_string),
        :oauth_signature_method => "PLAINTEXT",
        :oauth_signature => encode(consumer_secret + "&"),
        :oauth_timestamp => timestamp,
        :oauth_version => OAUTH_VERSION,
        :oauth_callback => callback
      })
    end

    def random_string
      (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
    end

    def timestamp
      Time.now.to_i.to_s 
    end

    def values_from_response response, keys_to_extract
      return values_from_query_string(response.body, keys_to_extract) if response.code == "200"
      raise "Request failed: #{response.body}"
    end

    def values_from_query_string query_string, keys_to_extract
      map = query_string_to_map(query_string)
      keys_to_extract.collect do |key|
        map[key]
      end
    end

    def query_string_to_map query_string 
      query_string.split('&').reduce({}) do |memo, key_value|
        (key,value) = key_value.split('=')
        memo[key]= value
        memo
      end
    end

    public

    def redirect_url auth_token
      "https://" + auth_host + auth_path + "?oauth_token=" + auth_token
    end

    private

    # use a config object or a Struct
    def access_token_and_guid auth_token, auth_token_secret, auth_verifier
      access_token_resp = https_connection(auth_host).request_post(access_token_path, access_token_req_params(auth_token, auth_token_secret, auth_verifier))      
      values_from_response(access_token_resp, ["oauth_token", "oauth_token_secret","xoauth_yahoo_guid"])
    end

    def access_token_req_params auth_token, auth_token_secret, auth_verifier
      to_query_string({
        :oauth_consumer_key => consumer_key,
        :oauth_nonce => encode(random_string),
        :oauth_signature_method => "PLAINTEXT",
        :oauth_signature => encode(consumer_secret + "&" + auth_token_secret),
        :oauth_version => OAUTH_VERSION,
        :oauth_timestamp => timestamp,
        :oauth_token => auth_token,
        :oauth_verifier => auth_verifier
      })
    end

  end
end
