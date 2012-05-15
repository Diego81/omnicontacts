require "net/http"
require "cgi"
require "openssl"

# This module contains a set of utility methods  related to the HTTP protocol.
module OmniContacts
  module HTTPUtils

    SSL_PORT = 443

    module_function

    def query_string_to_map query_string
      query_string.split('&').reduce({}) do |memo, key_value|
        (key, value) = key_value.split('=')
        memo[key]= value
        memo
      end
    end

    def to_query_string map
      map.collect do |key, value|
        key.to_s + "=" + value
      end.join("&")
    end

    # Encodes the given input according to RFC 3986
    def encode to_encode
      CGI.escape(to_encode)
    end

    # Calculates the url of the host from a Rack environment.
    # The result is in the form scheme://host:port
    # If port is 80 the result is scheme://host
    # According to Rack specification the HTTP_HOST variable is preferred over SERVER_NAME.
    def host_url_from_rack_env env
      port = ((env["SERVER_PORT"] == 80) && "") || ":#{env['SERVER_PORT']}"
      host = (env["HTTP_HOST"]) || (env["SERVER_NAME"] + port)
      "#{scheme(env)}://#{host}"
    end

    def scheme env
      if env['HTTPS'] == 'on'
        'https'
      elsif env['HTTP_X_FORWARDED_SSL'] == 'on'
        'https'
      elsif env['HTTP_X_FORWARDED_PROTO']
        env['HTTP_X_FORWARDED_PROTO'].split(',').first
      else
        env["rack.url_scheme"]
      end
    end

    # Classes including the module must respond to the ssl_ca_file message in order to use the following methods.
    # The response will be the path to the CA file to use when making https requests.
    # If the result of ssl_ca_file is nil no file is used. In this case a warn message is logged.
    private

    # Executes an HTTP GET request. 
    # It raises a RuntimeError if the response code is not equal to 200
    def http_get host, path, params
      connection = Net::HTTP.new(host)
      process_http_response connection.request_get(path + "?" + to_query_string(params))
    end

    # Executes an HTTP POST request over SSL
    # It raises a RuntimeError if the response code is not equal to 200
    def https_post host, path, params
      https_connection host do |connection|
        connection.request_post(path, to_query_string(params))
      end
    end

    # Executes an HTTP GET request over SSL
    # It raises a RuntimeError if the response code is not equal to 200
    def https_get host, path, params, headers =[]
      https_connection host do |connection|
        connection.request_get(path + "?" + to_query_string(params), headers)
      end
    end

    def https_connection (host)
      connection = Net::HTTP.new(host, SSL_PORT)
      connection.use_ssl = true
      if ssl_ca_file
        connection.ca_file = ssl_ca_file
      else
        logger << "No SSL ca file provided. It is highly reccomended to use one in production envinronments" if respond_to?(:logger) && logger
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      process_http_response(yield(connection))
    end

    def process_http_response response
      raise response.body if response.code != "200"
      response.body
    end

  end
end
