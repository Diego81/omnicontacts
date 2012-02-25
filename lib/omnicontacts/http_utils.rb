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

    def https_connection (host)
      result = Net::HTTP.new(host, SSL_PORT)
      result.use_ssl = true
      # use certificate in configuration file. If it is not there do not use SSL (use fake SSL)
      result.ca_file = ssl_ca_file_path
      result
    end

    def query_string_to_map query_string 
      query_string.split('&').reduce({}) do |memo, key_value|
        (key,value) = key_value.split('=')
        memo[key]= value
        memo
      end 
    end 

  end
end
