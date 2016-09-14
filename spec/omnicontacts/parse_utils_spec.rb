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

    it "returns only first name if no last name present" do
      result = full_name("John", nil)
      result.should eq("John")
    end

    it "returns only last name if no first name present" do
      result = full_name(nil, "McDonald")
      result.should eq("McDonald")
    end
  end

  describe "birthday_format" do
    it "returns nil if (!year && !month) || (!year && !day)" do
      result = birthday_format(nil, Date.today, nil)
      result.should eq(nil)

      result = birthday_format(Date.today.month, nil, nil)
      result.should eq(nil)
    end
  end

  describe "email_to_name" do
    it "create a probable name from email" do
      username_or_email = "foo.bar@test.com"
      result = email_to_name(username_or_email)
      result.should eq ['foo','bar',"foo bar"]
    end
  end
end
