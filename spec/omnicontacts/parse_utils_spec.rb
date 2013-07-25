require "spec_helper"
require "omnicontacts/parse_utils"

include OmniContacts::ParseUtils

describe OmniContacts::ParseUtils do
  describe "normalize_name" do
    it "should remove trailing spaces" do
      result = normalize_name("John ")
      result.should eq("John")
    end

    it "should preserve capitalization" do
      result = normalize_name("John McDonald")
      result.should eq("John McDonald")
    end
  end

  describe "full_name" do
    it "should preserve capitalization" do
      result = full_name("John", "McDonald")
      result.should eq("John McDonald")
    end
  end
end
