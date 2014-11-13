module OmniContacts
  
  VERSION = "0.3.5"

  MOUNT_PATH = "/import/"

  autoload :Builder, "omnicontacts/builder"
  autoload :Importer, "omnicontacts/importer"
  autoload :IntegrationTest, "omnicontacts/integration_test"

  class AuthorizationError < RuntimeError
  end


  def self.integration_test
    IntegrationTest.instance
  end
  
end
