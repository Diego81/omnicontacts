require "omnicontacts"

module OmniContacts
  class Builder < Rack::Builder
    def initialize(app, &block)
      if rack14?
        super
      else
        @app = app
        super(&block)
      end
    end

    def rack14?
      Rack.release.split('.')[1].to_i >= 4
    end

    def importer importer, *args
      middleware = OmniContacts::Importer.const_get(importer.to_s.capitalize)
      use middleware, *args
    rescue NameError
      raise LoadError, "Could not find importer #{importer}."
    end

    def call env
      @ins << @app unless rack14? || @ins.include?(@app)
      to_app.call(env)
    end
  end
end
