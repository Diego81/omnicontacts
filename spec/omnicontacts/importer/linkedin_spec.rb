require "spec_helper"
require "omnicontacts/importer/linkedin"

describe OmniContacts::Importer::Linkedin do

  let(:linkedin) { OmniContacts::Importer::Linkedin.new({}, "client_id", "client_secret", state: "ipsaeumeaque") }

  let(:contacts_as_json) do
    "{
      \n  \"_total\":  2,
      \n  \"values\":  [
        \n    {
          \n      \"firstName\":  \"Adolf\",
          \n      \"id\":  \"k71S5q6MKe\",
          \n      \"lastName\":  \"Witting\",
          \n      \"pictureUrl\":  \"https://media.licdn.com/mpr/mprx/0_mLnj-7szw130pFRLB8Op7-p1Sxoyv53U3B47Scp1Sxoyv53U3B47Scp1Sxoyv53U3B47Sc\"\n
        },
        \n    {
          \n      \"firstName\":  \"Emmet\",
          \n      \"id\":  \"ms5r3lI3J2\",
          \n      \"lastName\":  \"Little\",
          \n      \"pictureUrl\":  \"https://media.licdn.com/mpr/mprx/0_iH9m158zCdISt1X6iH9m158zCdISt1X6iH9m158zCdISt1X6iH9m158zCdISt1X6iH9m158zCdISt1X6\"\n
        }
      ]\n
    }"
  end

  describe "fetch_contacts_using_access_token" do
    let(:token) { "token" }
    let(:token_type) { nil }

    before(:each) do
      linkedin.instance_variable_set(:@env, {})
    end

    it "should request the contacts by specifying code in the http headers" do
      linkedin.should_receive(:https_get) do |host, path, params, headers|
        headers["Authorization"].should eq("Bearer #{token}")
        contacts_as_json
      end
      linkedin.fetch_contacts_using_access_token token, token_type
    end

    it "should correctly parse id, name, and profile picture for 1st contact" do
      linkedin.should_receive(:https_get).and_return(contacts_as_json)
      result = linkedin.fetch_contacts_using_access_token token, token_type

      result.size.should be(2)
      result.first[:id].should eq('k71S5q6MKe')
      result.first[:first_name].should eq('Adolf')
      result.first[:last_name].should eq('Witting')
      result.first[:name].should eq("Adolf Witting")
      result.first[:profile_picture].should eq("https://media.licdn.com/mpr/mprx/0_mLnj-7szw130pFRLB8Op7-p1Sxoyv53U3B47Scp1Sxoyv53U3B47Scp1Sxoyv53U3B47Sc")
    end

    it "should correctly parse id, name, and profile picture for 2nd contact" do
      linkedin.should_receive(:https_get).and_return(contacts_as_json)
      result = linkedin.fetch_contacts_using_access_token token, token_type
      result.size.should be(2)
      result.last[:id].should eq('ms5r3lI3J2')
      result.last[:first_name].should eq('Emmet')
      result.last[:last_name].should eq('Little')
      result.last[:name].should eq("Emmet Little")
      result.last[:profile_picture].should eq("https://media.licdn.com/mpr/mprx/0_iH9m158zCdISt1X6iH9m158zCdISt1X6iH9m158zCdISt1X6iH9m158zCdISt1X6iH9m158zCdISt1X6")
    end
  end
end