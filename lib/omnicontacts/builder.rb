require "omnicontacts"

module OmniContacts
  class Builder < Rack::Builder
    def initialize(app,&block)
      @app = app
      super(&block)
    end

    def importer importer, *args
      begin
        middleware = OmniContacts::Importer.const_get(importer.to_s.capitalize)
      rescue NameError
        raise LoadError, "Could not find importer #{importer}."
      end
      use middleware, *args
    end

    def call env
      @ins << @app unless @ins.include?(@app)
      to_app.call(env)
    end
  end
end
