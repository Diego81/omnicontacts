module OmniContacts
  module ParseUtils

    # return has of birthday day, month and year
    def birthday_format month, day, year
      return {:day => day.to_i, :month => month.to_i, :year => year.to_i}if year && month && day
      return {:day => day.to_i, :month => month.to_i, :year => nil} if !year && month && day
      return nil if (!year && !month) || (!year && !day)
    end

    # normalize the name
    def normalize_name name
      return nil if name.nil?
      name.chomp!
      name = name.split(' ').map(&:capitalize).join(' ')
      name.squeeze!(' ')
      name.strip!
      return name
    end

    # create a full name given the individual first and last name
    def full_name first_name, last_name
      return "#{first_name.capitalize} #{last_name.capitalize}" if first_name && last_name
      return "#{first_name}" if first_name && !last_name
      return "#{last_name}" if !first_name && last_name
      return nil
    end

    # create a username/name from a given email
    def email_to_name username_or_email
      username_or_email = username_or_email.split('@').first if username_or_email.include?('@')
      if group = (/(?<first>[a-z|A-Z]+)[\.|_](?<last>[a-z|A-Z]+)/).match(username_or_email)
        first_name = normalize_name(group[:first])
        last_name = normalize_name(group[:last])
        return first_name, last_name, "#{first_name} #{last_name}"
      end
      username = normalize_name(username_or_email)
      return username, nil, username
    end

    def yahoo_image_url yahoo_id
      return 'http://img.msg.yahoo.com/avatar.php?yids=' + yahoo_id if yahoo_id
    end

    def image_url email
      return nil if email.nil? || !email.include?('@')
      username, domain = *(email.split('@'))
      gmail_base_url = "https://profiles.google.com/s2/photos/profile/"
      yahoo_base_url = "http://img.msg.yahoo.com/avatar.php?yids="
      if domain.include?('gmail')
        image_url = gmail_base_url + username
      elsif domain.include?('yahoo')
        image_url = yahoo_base_url + username
      end
      image_url
    end

    def gmail_image_url gmail_id
      return "https://profiles.google.com/s2/photos/profile/" + gmail_id if gmail_id
    end

  end
end
