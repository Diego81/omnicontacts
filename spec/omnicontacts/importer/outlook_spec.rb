require "spec_helper"
require "omnicontacts/importer/outlook"

describe OmniContacts::Importer::Outlook do

  let(:permissions) { "Contacts.Read" }
  let(:outlook) { OmniContacts::Importer::Outlook.new({}, "app_id", "app_secret", {:permissions => permissions}) }

  let(:self_response) {
    '{
      "@odata.context": "https://outlook.office.com/api/v2.0/$metadata#Me",
      "@odata.id": "https://outlook.office.com/api/v2.0/Users(\'00034001-df52-d3d5-0000-000000000000@84df9e7f-e9f6-40af-b435-aaaaaaaaaaaa\')",
      "Id": "00034001-df52-d3d5-0000-000000000000@84df9e7f-e9f6-40af-b435-aaaaaaaaaaaa",
      "EmailAddress": "test.user@outlook.com",
      "DisplayName": "Test User",
      "Alias": "puid-00034001DF52D3D5",
      "MailboxGuid": "00034001-df52-d3d5-0000-000000000000"
    }'
  }

  let(:contacts_as_json) {
    '{
      "@odata.context": "https://outlook.office.com/api/v2.0/$metadata#Me/Contacts",
      "value": [{
        "@odata.id": "https://outlook.office.com/api/v2.0/Users(\'00034001-df52-d3d5-0000-000000000000@84df9e7f-e9f6-40af-b435-aaaaaaaaaaaa\')/Contacts(\'AQMkADAwATM0MDAAMS1kZjUyLWQzZDUtMDACLTAwCgBGAAADQ1hAWLJpwk6DZYyOhnclvgcAxCL3G7jnpkiRUVmiNrhjJgAAAgEOAAAAxCL3G7jnpkiRUVmiNrhjJgAAAixsAAAA\')",
        "@odata.etag": "W/\"EQAAABYAAADEIvcbuOemSJFRWaI2uGMmAAAAlo4t\"",
        "Id": "AQMkADAwATM0MDAAMS1kZjUyLWQzZDUtMDACLTAwCgBGAAADQ1hAWLJpwk6DZYyOhnclvgcAxCL3G7jnpkiRUVmiNrhjJgAAAgEOAAAAxCL3G7jnpkiRUVmiNrhjJgAAAixsAAAA",
        "CreatedDateTime": "2016-04-13T21:25:24Z",
        "LastModifiedDateTime": "2016-04-14T19:36:55Z",
        "ChangeKey": "EQAAABYAAADEIvcbuOemSJFRWaI2uGMmAAAAlo4t",
        "Categories": [],
        "ParentFolderId": "AQMkADAwATM0MDAAMS1kZjUyLWQzZDUtMDACLTAwCgAuAAADQ1hAWLJpwk6DZYyOhnclvgEAxCL3G7jnpkiRUVmiNrhjJgAAAgEOAAAA",
        "Birthday": "1604-08-14T00:00:00Z",
        "FileAs": "Contact, First",
        "DisplayName": "First Contact",
        "GivenName": "First",
        "Initials": null,
        "MiddleName": null,
        "NickName": null,
        "Surname": "Contact",
        "Title": null,
        "YomiGivenName": null,
        "YomiSurname": null,
        "YomiCompanyName": null,
        "Generation": null,
        "EmailAddresses": [{
          "Name": "contact.first@email.com",
          "Address": "contact.first@email.com"
        }, {
          "Name": "contact.second@email.com",
          "Address": "contact.second@email.com"
        }],
        "ImAddresses": [],
        "JobTitle": null,
        "CompanyName": null,
        "Department": null,
        "OfficeLocation": null,
        "Profession": null,
        "BusinessHomePage": null,
        "AssistantName": null,
        "Manager": null,
        "HomePhones": [],
        "MobilePhone1": null,
        "BusinessPhones": [],
        "HomeAddress": {
          "Street": "address1",
          "City": "city",
          "State": "state",
          "CountryOrRegion": "US",
          "PostalCode": "89111"
        },
        "BusinessAddress": {},
        "OtherAddress": {},
        "SpouseName": null,
        "PersonalNotes": null,
        "Children": []
      }]
    }'
  }

  describe "fetch_contacts_using_access_token" do

    let(:access_token) { "access_token" }
    let(:token_type) { "token_type" }

    before(:each) do
      outlook.instance_variable_set(:@env, {"HTTP_HOST" => "http://example.com"})
    end

    it "should request the contacts by providing the authorization header with token_type and access_token" do
      outlook.should_receive(:https_get) do |host, path, params, headers|
        params.should eq({})
        headers["Authorization"].should eq("token_type access_token")
        self_response
      end

      outlook.should_receive(:https_get) do |host, path, params, headers|
        params.should eq({})
        headers["Authorization"].should eq("token_type access_token")
        contacts_as_json
      end
      outlook.fetch_contacts_using_access_token access_token, token_type
    end

    it "should set requested permissions in the authorization url" do
      outlook.authorization_url.should match(/scope=#{Regexp.quote(CGI.escape(permissions))}/)
    end

    it "should correctly parse id, name and email" do
      outlook.should_receive(:https_get).and_return(self_response)
      outlook.should_receive(:https_get).and_return(contacts_as_json)
      result = outlook.fetch_contacts_using_access_token access_token, token_type

      result.size.should be(1)
      result.first[:id].should eq('AQMkADAwATM0MDAAMS1kZjUyLWQzZDUtMDACLTAwCgBGAAADQ1hAWLJpwk6DZYyOhnclvgcAxCL3G7jnpkiRUVmiNrhjJgAAAgEOAAAAxCL3G7jnpkiRUVmiNrhjJgAAAixsAAAA')
      result.first[:first_name].should eq("First")
      result.first[:last_name].should eq("Contact")
      result.first[:name].should eq("First Contact")
      result.first[:email].should eq("contact.first@email.com")
      result.first[:birthday].should eq({ :day => 14, :month => 8, :year => nil })
      result.first[:address_1].should eq("address1")
      result.first[:address_2].should be_nil
      result.first[:city].should eq("city")
      result.first[:region].should eq("state")
      result.first[:postcode].should eq("89111")
      result.first[:country].should eq("US")
      result.first[:gender].should be_nil
      result.first[:profile_picture].should be_nil
      result.first[:relation].should be_nil
    end

    it "should correctly parse and set logged in user information" do
      outlook.should_receive(:https_get).and_return(self_response)
      outlook.should_receive(:https_get).and_return(contacts_as_json)

      outlook.fetch_contacts_using_access_token access_token, token_type

      user = outlook.instance_variable_get(:@env)["omnicontacts.user"]
      user.should_not be_nil
      user[:id].should eq('00034001-df52-d3d5-0000-000000000000@84df9e7f-e9f6-40af-b435-aaaaaaaaaaaa')
      user[:first_name].should eq("Test")
      user[:last_name].should eq("User")
      user[:name].should eq("Test User")
      user[:email].should eq("test.user@outlook.com")
      user[:gender].should be_nil
      user[:birthday].should be_nil
    end
  end

end
