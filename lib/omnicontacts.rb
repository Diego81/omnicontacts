module OmniContacts

  VERSION = "0.1.7"

  autoload :Builder, "omnicontacts/builder"
  autoload :Importer, "omnicontacts/importer"

  class AuthorizationError < RuntimeError
  end

end
