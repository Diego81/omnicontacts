require "omnicontacts"

module OmniContacts
  class Builder < Rack::Builder
    def initialize(app, &block)
      if rack13?
        @app = app
        super(&block)
      else
        super
      end
    end

    def rack13?
      major, minor = Rack.release.split('.').first(2)
      major.to_i == 1 && minor.to_i <= 3
    end

    def importer importer, *args
      middleware = OmniContacts::Importer.const_get(importer.to_s.capitalize)
      use middleware, *args
    rescue NameError
      raise LoadError, "Could not find importer #{importer}."
    end

    def call env
      @ins << @app if rack13? && !@ins.include?(@app)
      to_app.call(env)
    end
  end
end
