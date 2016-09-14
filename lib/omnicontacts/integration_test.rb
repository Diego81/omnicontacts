require 'singleton'

class IntegrationTest
  include Singleton

  attr_accessor :enabled

  def initialize
    enabled = false
    clear_mocks
  end

  def clear_mocks
    @user_mocks = {}
    @contact_mocks = {}
  end

  def mock provider, contacts, user = {}
    @contact_mocks[provider.to_sym] = contacts
    @user_mocks[provider.to_sym] = user
  end

  def mock_authorization_from_user provider
    [302, {"Content-Type" => "application/x-www-form-urlencoded", "location" => provider.redirect_path}, []]
  end

  def mock_fetch_contacts provider
    result = @contact_mocks[provider.class_name.to_sym] || []
    if result.is_a? Array
      result
    elsif result.is_a? Hash
      [result]
    else
      raise result.to_s
    end
  end

  def mock_fetch_user provider
    @user_mocks[provider.class_name.to_sym] || {}
  end
end
