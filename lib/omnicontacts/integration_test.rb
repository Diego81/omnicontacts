require 'singleton'

class IntegrationTest
  include Singleton
  
  attr_accessor :enabled
  
  def initialize
    enabled = false
    clear_mocks
  end
  
  def clear_mocks
    @mock = {}
  end
  
  def mock provider, mock
    @mock[provider.to_sym] = mock
  end
  
  def mock_authorization_from_user provider
    [302, {"location" => provider.redirect_path}, []]
  end
  
  def mock_fetch_contacts provider
    result = @mock[provider.class_name.to_sym] || []
    if result.is_a? Array
      result
    elsif result.is_a? Hash
      [result]
    else
      raise result.to_s
    end
  end
  
end