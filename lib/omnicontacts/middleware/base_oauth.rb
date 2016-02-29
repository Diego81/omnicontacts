# This class contains the common behavior for middlewares
# implementing either versions of OAuth.
#
# Extending classes are required to implement
# the following methods:
# * request_authorization_from_user
# * fetch_contatcs
module OmniContacts
  module Middleware
    class BaseOAuth

      attr_reader :ssl_ca_file

      def initialize app, options
        @app = app
        @listening_path = MOUNT_PATH + class_name
        @ssl_ca_file = options[:ssl_ca_file]
      end

      def class_name
        self.class.name.split('::').last.downcase
      end

      # Rack callback. It handles three cases:
      # * user visit middleware entry point.
      #   In this case request_authorization_from_user is called
      # * user is redirected back to the application
      #   from the authorization site. In this case the list
      #   of contacts is fetched and stored in the variables
      #   omnicontacts.contacts within the Rack env variable.
      #   Once that is done the next middleware component is called.
      # * user visits any other resource. In this case the request
      #   is simply forwarded to the next middleware component.
      def call env
        @env = env
        if env["PATH_INFO"] =~ /^#{@listening_path}\/?$/
          session['omnicontacts.params'] = Rack::Request.new(env).params
          handle_initial_request
        elsif env["PATH_INFO"] =~ /^#{redirect_path}/
          env['omnicontacts.params'] = session.delete('omnicontacts.params')
          handle_callback
        else
          @app.call(env)
        end
      end

      private

      def test_mode?
        IntegrationTest.instance.enabled
      end

      def handle_initial_request
        execute_and_rescue_exceptions do
          if test_mode?
            IntegrationTest.instance.mock_authorization_from_user(self)
          else
            request_authorization_from_user
          end
        end
      end

      def handle_callback
        execute_and_rescue_exceptions do
          @env["omnicontacts.contacts"] = if test_mode?
            IntegrationTest.instance.mock_fetch_contacts(self)
          else
            fetch_contacts
          end
          set_current_user IntegrationTest.instance.mock_fetch_user(self) if test_mode?
          @app.call(@env)
        end
      end

      def set_current_user user
        @env["omnicontacts.user"] = user
      end

      #  This method rescues executes a block of code and
      #  rescue all exceptions. In case of an exception the
      #  user is redirected to the failure endpoint.
      def execute_and_rescue_exceptions
        yield
      rescue AuthorizationError => e
        handle_error :not_authorized, e
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        handle_error :timeout, e
      rescue ::RuntimeError => e
        handle_error :internal_error, e
      end

      def handle_error error_type, exception
        logger.puts("Error #{error_type} while processing #{@env["PATH_INFO"]}: #{exception.message}") if logger
        failure_url = "#{ MOUNT_PATH }failure?error_message=#{error_type}&importer=#{class_name}"
        params_url = append_request_params(failure_url)
        target_url = append_state_query(params_url)
        [302, {"Content-Type" => "text/html", "location" => target_url}, []]
      end

      def session
        raise "You must provide a session to use OmniContacts" unless @env["rack.session"]
        @env["rack.session"]
      end

      def logger
        @env["rack.errors"] if @env
      end

      def base_prop_name
        "omnicontacts." + class_name
      end

      def append_request_params(target_url)
        return target_url unless @env['omnicontacts.params']
        params = Rack::Utils.build_query(@env['omnicontacts.params'])
        unless params.nil? or params.empty?
          target_url = target_url + (target_url.include?("?")?"&":"?") + params
        end
        return target_url
      end

      def append_state_query(target_url)
        state = Rack::Utils.parse_query(@env['QUERY_STRING'])['state']
        unless state.nil?
          target_url = target_url + (target_url.include?("?")?"&":"?") + 'state=' + state
        end

        return target_url
      end
    end
  end
end
