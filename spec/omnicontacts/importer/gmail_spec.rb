require "spec_helper"
require "omnicontacts/importer/gmail"

describe OmniContacts::Importer::Gmail do

  let(:gmail) { OmniContacts::Importer::Gmail.new({}, "client_id", "client_secret") }

  let(:contacts_as_xml) {
    "<entry xmlns:gd='http://schemas.google.com/g/2005'>
       <gd:name>
         <gd:fullName>Edward Bennet</gd:fullName>
       </gd:name>
       <gd:email rel='http://schemas.google.com/g/2005#work' primary='true' address='bennet@gmail.com'/>
     </entry>"
  }

  let(:contact_without_fullname) {
    "<entry xmlns:gd='http://schemas.google.com/g/2005'>
       <gd:name/>
       <gd:email rel='http://schemas.google.com/g/2005#work' primary='true' address='bennet@gmail.com'/>
     </entry>"
  }

  describe "fetch_contacts_using_access_token" do

    let(:token) { "token" }
    let(:token_type) { "token_type" }

    it "should request the contacts by specifying version and code in the http headers" do
      gmail.should_receive(:https_get) do |host, path, params, headers|
        headers["GData-Version"].should eq("3.0")
        headers["Authorization"].should eq("#{token_type} #{token}")
        contacts_as_xml
      end
      gmail.fetch_contacts_using_access_token token, token_type
    end

    it "should correctly parse name and email" do
      gmail.should_receive(:https_get).and_return(contacts_as_xml)
      result = gmail.fetch_contacts_using_access_token token, token_type
      result.size.should be(1)
      result.first[:name].should eq("Edward Bennet")
      result.first[:email].should eq("bennet@gmail.com")
    end

    it "should handle contact without fullname" do
      gmail.should_receive(:https_get).and_return(contact_without_fullname)
      result = gmail.fetch_contacts_using_access_token token, token_type
      result.size.should be(1)
      result.first[:name].should be_nil
      result.first[:email].should eq("bennet@gmail.com")
    end

  end
end
