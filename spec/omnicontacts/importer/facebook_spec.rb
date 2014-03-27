require "spec_helper"
require "omnicontacts/importer/facebook"

describe OmniContacts::Importer::Facebook do

  let(:facebook) { OmniContacts::Importer::Facebook.new({}, "client_id", "client_secret") }

  let(:self_response) {
    '{
        "first_name":"Chris",
        "last_name":"Johnson",
        "name":"Chris Johnson",
        "id":"543216789",
        "gender":"male",
        "birthday":"06/21/1982",
        "significant_other":{"id": "243435322"},
        "relationship_status": "Married",
        "picture":{"data":{"url":"http://profile.ak.fbcdn.net/hprofile-ak-snc6/186364_543216789_2089044200_q.jpg","is_silhouette":false}},
        "email": "chrisjohnson@gmail.com"
    }'
  }

  let(:spouse_response) {
    '{
        "first_name":"Mary",
        "last_name":"Johnson",
        "name":"Mary Johnson",
        "id":"243435322",
        "gender":"female",
        "birthday":"01/21",
        "picture":{"data":{"url":"http://profile.ak.fbcdn.net/hprofile-ak-snc6/186364_243435322_2089044200_q.jpg","is_silhouette":false}}
    }'
  }

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

    before(:each) do
      facebook.instance_variable_set(:@env, {})
    end

    it "should request the contacts by providing the token in the url" do
      facebook.should_receive(:https_get) do |host, self_path, params, headers|
        params[:access_token].should eq(token)
        params[:fields].should eq('first_name,last_name,name,id,gender,birthday,picture,relationship_status,significant_other,email')
        self_response
      end
      facebook.should_receive(:https_get) do |host, spouse_path, params, headers|
        params[:access_token].should eq(token)
        params[:fields].should eq('first_name,last_name,name,id,gender,birthday,picture')
        spouse_response
      end
      facebook.should_receive(:https_get) do |host, path, params, headers|
        params[:access_token].should eq(token)
        params[:fields].should eq('first_name,last_name,name,id,gender,birthday,picture,relationship')
        contacts_as_json
      end.exactly(1).times
      facebook.should_receive(:https_get) do |host, path, params, headers|
        params[:access_token].should eq(token)
        params[:fields].should eq('first_name,last_name,name,id,gender,birthday,picture')
        contacts_as_json
      end.exactly(1).times

      facebook.fetch_contacts_using_access_token token, token_type
    end

    it "should correctly parse id, name,email,gender, birthday, profile picture and relation" do
      1.times { facebook.should_receive(:https_get).and_return(self_response) }
      1.times { facebook.should_receive(:https_get) }
      2.times { facebook.should_receive(:https_get).and_return(contacts_as_json) }
      result = facebook.fetch_contacts_using_access_token token, token_type
      result.size.should be(1)
      result.first[:id].should eq('608061886')
      result.first[:first_name].should eq('John')
      result.first[:last_name].should eq('Smith')
      result.first[:name].should eq('John Smith')
      result.first[:email].should be_nil
      result.first[:gender].should eq('male')
      result.first[:birthday].should eq({:day=>21, :month=>06, :year=>nil})
      result.first[:profile_picture].should eq('https://graph.facebook.com/608061886/picture')
      result.first[:relation].should eq('cousin')
    end

    it "should correctly parse and set logged in user information" do
      1.times { facebook.should_receive(:https_get).and_return(self_response) }
      1.times { facebook.should_receive(:https_get) }
      2.times { facebook.should_receive(:https_get).and_return(contacts_as_json) }

      facebook.fetch_contacts_using_access_token token, token_type

      user = facebook.instance_variable_get(:@env)["omnicontacts.user"]
      user.should_not be_nil
      user[:id].should eq("543216789")
      user[:first_name].should eq("Chris")
      user[:last_name].should eq("Johnson")
      user[:name].should eq("Chris Johnson")
      user[:email].should eq("chrisjohnson@gmail.com")
      user[:gender].should eq("male")
      user[:birthday].should eq({:day=>21, :month=>06, :year=>1982})
      user[:profile_picture].should eq("https://graph.facebook.com/543216789/picture")
    end
  end

end
