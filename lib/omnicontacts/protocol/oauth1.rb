require "omnicontacts/http_utils"

module OmniContacts

  module OAuth1 
    include HTTPUtils

    OAUTH_VERSION = "1.0"

    def request_token
      request_token_response = https_post(auth_host, request_token_path, request_token_req_params)
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
      (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
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
          raise query_string
        end
      end
    end

    public

    def redirect_url auth_token
      "https://" + auth_host + auth_path + "?oauth_token=" + auth_token
    end

    # use a config object or a Struct
    def access_token auth_token, auth_token_secret, auth_verifier, additional_fields_to_extract = []
      access_token_resp = https_post(auth_host, access_token_path, access_token_req_params(auth_token, auth_token_secret, auth_verifier))      
      values_from_query_string(access_token_resp, ( ["oauth_token", "oauth_token_secret"] + additional_fields_to_extract) )
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

  end
end
