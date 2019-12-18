module OmniContacts
  module Importer

    autoload :Gmail, "omnicontacts/importer/gmail"
    autoload :Slack, "omnicontacts/importer/slack"
    autoload :Yahoo, "omnicontacts/importer/yahoo"
    autoload :Hotmail, "omnicontacts/importer/hotmail"
    autoload :Outlook, "omnicontacts/importer/outlook"
    autoload :Facebook, "omnicontacts/importer/facebook"
    autoload :Linkedin, "omnicontacts/importer/linkedin"

  end
end
