require "rack"

module OmniContacts

  autoload :Builder, "omnicontacts/builder"
  autoload :Gmail, "omnicontacts/importer/gmail"
  autoload :Yahoo, "omnicontacts/importer/yahoo"
  autoload :Hotmail, "omnicontacts/importer/hotmail"

end
