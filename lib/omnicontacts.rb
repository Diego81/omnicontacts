require "rack"

module OmniContacts

  VERSION = "0.1.0"

  autoload :Builder, "omnicontacts/builder"
  autoload :Gmail, "omnicontacts/importer/gmail"
  autoload :Yahoo, "omnicontacts/importer/yahoo"
  autoload :Hotmail, "omnicontacts/importer/hotmail"

end
