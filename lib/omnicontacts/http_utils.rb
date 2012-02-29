module OmniContacts
  module HTTPUtils

    SSL_PORT = 443

    module_function

    def to_query_string params
      params.collect do |key, value|
        key.to_s + "=" + value
      end.join("&")
    end

    def encode to_encode
      CGI.escape(to_encode)
    end

    def https_post host,path, params
      response = https_connection(host).request_post(path, to_query_string(params))
      raise response.body if response.code != "200"
      response.body
    end

    def https_connection (host)
      result = Net::HTTP.new(host, SSL_PORT)
      result.use_ssl = true
      if ssl_ca_file
        result.ca_file = ssl_ca_file
      else
        # log warning
        result.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      result
    end

    def query_string_to_map query_string 
      query_string.split('&').reduce({}) do |memo, key_value|
        (key,value) = key_value.split('=')
        memo[key]= value
        memo
      end 
    end 

    def host_url_from_rack_env env
      port = ( (env["SERVER_PORT"] == 80) && "") || ":#{env['SERVER_PORT']}"  
      host = (env["HTTP_HOST"]) || (env["SERVER_NAME"] + port)
      env["rack.url_scheme"] + "://" + host
    end

  end
end
