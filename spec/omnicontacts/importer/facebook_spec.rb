require "spec_helper"
require "omnicontacts/importer/facebook"

describe OmniContacts::Importer::Facebook do

  let(:facebook) { OmniContacts::Importer::Facebook.new({}, "client_id", "client_secret") }

  let(:contacts_as_json) {
    '{"data":[
        {
          "first_name":"John",
          "last_name":"Smith",
          "name":"John Smith",
          "id":"608061886",
          "gender":"male",
          "birthday":"06/21",
          "relationship":"cousin",
          "picture":{"data":{"url":"http://profile.ak.fbcdn.net/hprofile-ak-snc6/186364_608061886_2089044200_q.jpg","is_silhouette":false}}
        }
      ]
    }' }

  describe "fetch_contacts_using_access_token" do
    let(:token) { "token" }
    let(:token_type) { "token_type" }


    it "should request the contacts by providing the token in the url and fields params only for family and friends requests" do
      facebook.should_receive(:https_get) do |host, path, params, headers|
        params[:access_token].should eq(token)
        params[:fields].should be_nil
        contacts_as_json
      end
      facebook.should_receive(:https_get) do |host, path, params, headers|
        params[:access_token].should eq(token)
        params[:fields].should eq('first_name,last_name,name,id,gender,birthday,picture')
        contacts_as_json
      end.at_most(2).times
      facebook.fetch_contacts_using_access_token token, token_type
    end

    it "should correctly parse id, name,email,gender, birthday, image source and relation" do
      3.times { facebook.should_receive(:https_get).and_return(contacts_as_json) }
      result = facebook.fetch_contacts_using_access_token token, token_type
      result.size.should be(1)
      result.first[:id].should eq('608061886')
      result.first[:first_name].should eq('John')
      result.first[:last_name].should eq('Smith')
      result.first[:name].should eq('John Smith')
      result.first[:email].should be_nil
      result.first[:gender].should eq('male')
      result.first[:birthday].should eq({:day=>21, :month=>06, :year=>nil})
      result.first[:image_source].should eq('http://profile.ak.fbcdn.net/hprofile-ak-snc6/186364_608061886_2089044200_q.jpg')
      result.first[:relation].should eq('cousin')
    end
  end

end
