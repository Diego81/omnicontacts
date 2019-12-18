require "spec_helper"
require "omnicontacts/importer/slack"

describe OmniContacts::Importer::Slack do
  let(:slack) { OmniContacts::Importer::Slack.new({}, "client_id", "client_secret") }

  let(:response_as_json) {
    '{
        "ok": true,
        "members": [
          {
            "id": "SFSDFSDFS",
            "profile":
            {
                "real_name": "John Smith",
                "image_original": "https://avatars.slack-edge.com/2017-11-30/sdfswersdfsfsdfsdfsfasdf.png",
                "email": "johnsmith@domain.tld",
                "first_name": "John",
                "last_name": "Smith"
            }
          }
        ]
     }'
  }

  describe "fetch_contacts_using_access_token" do
    let(:token) { "token" }
    let(:token_type) { "token_type" }

    before(:each) do
      slack.instance_variable_set(:@env, {})
    end

    it "should correctly parse id, name, email, profile picture" do
      slack.should_receive(:https_get).and_return(response_as_json)
      result = slack.fetch_contacts_using_access_token token, token_type

      result.first[:id].should eq('SFSDFSDFS')
      result.first[:first_name].should eq('John')
      result.first[:last_name].should eq('Smith')
      result.first[:name].should eq("John Smith")
      result.first[:email].should eq("johnsmith@domain.tld")
      result.first[:profile_picture].should eq("https://avatars.slack-edge.com/2017-11-30/sdfswersdfsfsdfsdfsfasdf.png")
    end

  end
end
