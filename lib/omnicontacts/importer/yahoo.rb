require "omnicontacts/protocol/oauth1"
require "json"

module OmniContacts
  class Yahoo 
    include OAuth1 

    attr_reader :consumer_key, :consumer_secret, :ssl_ca_file, :auth_host, :request_token_path, :auth_path, :access_token_path

    def initialize app, consumer_key, consumer_secret, token_persistence_class, options = {}
      @app = app
      @token_persistence_class = token_persistence_class
      @consumer_key = consumer_key
      @consumer_secret = consumer_secret
      @callback_path = options[:callback_path] || "/contacts/yahoo/callback"
      @ssl_ca_file = options[:ssl_ca_file]
      @auth_host = "api.login.yahoo.com"
      @request_token_path = "/oauth/v2/get_request_token"
      @auth_path = "/oauth/v2/request_auth"
      @access_token_path = "/oauth/v2/get_token"
    end

    def call env
      @env = env
      if env["PATH_INFO"] == "/contacts/yahoo"
        obtain_token_and_redirect
      else
        if env["PATH_INFO"] =~ /^#{@callback_path}/
          env["omnicontacts.contacts"] = fetch_contacts(env)
        end
        @app.call env
      end
    end

    def callback
      host_url_from_rack_env(@env) + @callback_path
    end

    private

    def obtain_token_and_redirect
      (auth_token, auth_token_secret) = request_token
      token = @token_persistence_class.new
      token.oauth_token = auth_token
      token.oauth_token_secret = auth_token_secret
      redirect_to_yahoo_site(auth_token) if token.save
    end

    def redirect_to_yahoo_site auth_token
      [302, {"location" => redirect_url(auth_token)}, []]
    end

    def fetch_contacts env
      params = query_string_to_map(env["QUERY_STRING"])
      token = @token_persistence_class.find_by_oauth_token(params["oauth_token"])
      contacts_from_token_and_verifier(token.oauth_token, token.oauth_token_secret, params["oauth_verifier"])
    end

    def contacts_from_token_and_verifier auth_token, auth_token_secret, auth_verifier
      (access_token, access_token_secret, guid) = access_token_and_guid(auth_token, auth_token_secret, auth_verifier)
      contacts_url = "http://social.yahooapis.com/v1/user/#{guid}/contacts"
      contacts_response = Net::HTTP.get_response(URI(contacts_url + "?" + contacts_req_params(access_token, access_token_secret, contacts_url)))
      contacts_from_response contacts_response
    end

    def contacts_req_params access_token, access_token_secret, contacts_url
      params = {
        "format" => "json",
        "oauth_consumer_key" => @consumer_key,
        "oauth_nonce" => encode(random_string),
        "oauth_signature_method" => "HMAC-SHA1",
        "oauth_timestamp" => timestamp,
        "oauth_token" => access_token,
        "oauth_version" => OAUTH_VERSION,
        "view" => "compact"
      } 
      params["oauth_signature"] = oauth_signature(contacts_url, params, access_token_secret)
      to_query_string(params)
    end

    def oauth_signature url, params, secret
      encoded_method = encode("GET")
      encoded_url = encode(url)
      # params must be in alphabetical order
      encoded_params = encode(to_query_string(params.sort))
      base_string = encoded_method + '&' + encoded_url + '&' + encoded_params
      key = encode(@consumer_secret) + '&' + secret
      hmac_sha1 = OpenSSL::HMAC.digest('sha1', key, base_string)
      # base64 encode results must be stripped
      encode(Base64.encode64(hmac_sha1).strip)
    end

    def contacts_from_response response
      raise "Request failed" if response.code != "200"
      json = JSON.parse(response.body)
      result = []
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
