require "spec_helper"
require "omnicontacts/importer/gmail"

describe OmniContacts::Importer::Gmail do

  let(:gmail) { OmniContacts::Importer::Gmail.new({}, "client_id", "client_secret") }

  let(:gmail_with_scope_args) { OmniContacts::Importer::Gmail.new({}, "client_id", "client_secret", {scope: "https://www.googleapis.com/auth/contacts.readonly https://www.googleapis.com/auth/userinfo#email https://www.googleapis.com/auth/userinfo.profile"}) }
  
  let(:self_response) {
    '{
      "id":"16482944006464829443",
      "email":"chrisjohnson@gmail.com",
      "name":"Chris Johnson",
      "given_name":"Chris",
      "family_name":"Johnson",
      "picture":"https://lh3.googleusercontent.com/-b8aFbTBM/AAAAAAI/IWA/vsek/photo.jpg",
      "gender":"male",
      "birthday":"1982-06-21"
    }'
  }

  let(:contacts_as_json) {
    '{"version":"1.0","encoding":"UTF-8",
        "feed":{
          "xmlns":"http://www.w3.org/2005/Atom",
          "xmlns$openSearch":"http://a9.com/-/spec/opensearch/1.1/",
          "xmlns$gContact":"http://schemas.google.com/contact/2008",
          "xmlns$batch":"http://schemas.google.com/gdata/batch",
          "xmlns$gd":"http://schemas.google.com/g/2005",
          "gd$etag":"W/\"C0YHRno7fSt7I2A9WhBSQ0Q.\"",

          "id":{"$t":"logged_in_user@gmail.com"},
          "updated":{"$t":"2013-02-20T20:12:17.405Z"},
          "category":[{
            "scheme":"http://schemas.google.com/g/2005#kind",
            "term":"http://schemas.google.com/contact/2008#contact"
           }],

          "title":{"$t":"Users\'s Contacts"},
          "link":[
            {"rel":"http://schemas.google.com/contacts/2008/rel#photo","type":"image/*",
             "href":"https://www.google.com/m8/feeds/photos/media/logged_in_user%40gmail.com/6b41d030b05abc","gd$etag":"\"VSxuN0cISit7I2A1UVUSdy12KHwgBFkE333.\""},
            {"rel":"alternate","type":"text/html","href":"http://www.google.com/"},
            {"rel":"http://schemas.google.com/g/2005#feed","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full"},
            {"rel":"http://schemas.google.com/g/2005#post","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full"},
            {"rel":"http://schemas.google.com/g/2005#batch","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/batch"},
            {"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full?alt\u003djson\u0026max-results\u003d1"},
            {"rel":"next","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full?alt\u003djson\u0026start-index\u003d2\u0026max-results\u003d1"}
          ],
          "author":[{"name":{"$t":"Edward"},"email":{"$t":"logged_in_user@gmail.com"}}],
          "generator":{"version":"1.0","uri":"http://www.google.com/m8/feeds","$t":"Contacts"},
          "openSearch$totalResults":{"$t":"1007"},
          "openSearch$startIndex":{"$t":"1"},
          "openSearch$itemsPerPage":{"$t":"1"},
          "entry":[
            {
            "gd$etag":"\"R3oyfDVSLyt7I2A9WhBTSEULRA0.\"",
            "id":{"$t":"http://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/base/1"},
            "updated":{"$t":"2013-02-14T22:36:36.494Z"},
            "app$edited":{"xmlns$app":"http://www.w3.org/2007/app","$t":"2013-02-14T22:36:36.494Z"},
            "category":[{"scheme":"http://schemas.google.com/g/2005#kind","term":"http://schemas.google.com/contact/2008#contact"}],
            "title":{"$t":"Edward Bennet"},
            "link":[
              {"rel":"http://schemas.google.com/contacts/2008/rel#photo","type":"image/*",
               "href":"https://www.google.com/m8/feeds/photos/media/logged_in_user%40gmail.com/6b41d030b05abc", "gd$etag":"\"VSxuN0cISit7I2A1UVUSdy12KHwgBFkE333.\""},
              {"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/1"},
              {"rel":"edit","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/1"}
            ],
            "gd$name":{
              "gd$fullName":{"$t":"Edward Bennet"},
              "gd$givenName":{"$t":"Edward"},
              "gd$familyName":{"$t":"Bennet"}
            },
            "gd$organization":[{"rel":"http://schemas.google.com/g/2005#other","gd$orgName":{"$t":"Google"},"gd$orgTitle":{"$t":"Master Developer"}}],
            "gContact$birthday":{"when":"1954-07-02"},
            "gContact$relation":{"rel":"father"},
            "gContact$gender":{"value":"male"},
            "gContact$event":[{"rel":"anniversary","gd$when":{"startTime":"1983-04-21"}},{"label":"New Job","gd$when":{"startTime":"2014-12-01"}}],
            "gd$email":[{"rel":"http://schemas.google.com/g/2005#other","address":"bennet@gmail.com","primary":"true"}],
            "gContact$groupMembershipInfo":[{"deleted":"false","href":"http://www.google.com/m8/feeds/groups/logged_in_user%40gmail.com/base/6"}],
            "gd$structuredPostalAddress":[{"rel":"http://schemas.google.com/g/2005#home","gd$formattedAddress":{"$t":"1313 Trashview Court\nApt. 13\nNowheresville, OK 66666"},"gd$street":{"$t":"1313 Trashview Court\nApt. 13"},"gd$postcode":{"$t":"66666"},"gd$country":{"code":"VA","$t":"Valoran"},"gd$city":{"$t":"Nowheresville"},"gd$region":{"$t":"OK"}}],
            "gd$phoneNumber":[{"rel":"http://schemas.google.com/g/2005#mobile","uri":"tel:+34-653-15-76-88","$t":"653157688"}]
          },
          {
            "gd$etag":"\"R3oyfDVSLyt7I2A9WhBTSEULRA0.\"",
            "id":{"$t":"http://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/base/1"},
            "updated":{"$t":"2013-02-15T22:36:36.494Z"},
            "app$edited":{"xmlns$app":"http://www.w3.org/2007/app","$t":"2013-02-15T22:36:36.494Z"},
            "category":[{"scheme":"http://schemas.google.com/g/2005#kind","term":"http://schemas.google.com/contact/2008#contact"}],
            "title":{"$t":"Emilia Fox"},
            "link":[
              {"rel":"http://schemas.google.com/contacts/2008/rel#photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/logged_in_user%40gmail.com/1"},
              {"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/1"},
              {"rel":"edit","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/1"}
            ],
            "gd$name":{
              "gd$fullName":{"$t":"Emilia Fox"},
              "gd$givenName":{"$t":"Emilia"},
              "gd$familyName":{"$t":"Fox"}
            },
            "gContact$birthday":{"when":"1974-02-10"},
            "gContact$relation":[{"rel":"spouse"}],
            "gContact$gender":{"value":"female"},
            "gd$email":[{"rel":"http://schemas.google.com/g/2005#other","address":"emilia.fox@gmail.com","primary":"true"}],
            "gContact$groupMembershipInfo":[{"deleted":"false","href":"http://www.google.com/m8/feeds/groups/logged_in_user%40gmail.com/base/6"}]
          }]
        }
      }'
  }

  describe "fetch_contacts_using_access_token" do
    let(:token) { "token" }
    let(:token_type) { "token_type" }

    before(:each) do
      gmail.instance_variable_set(:@env, {})
      gmail_with_scope_args.instance_variable_set(:@env, {})
    end

    it "should request the contacts by specifying version and code in the http headers" do
      gmail.should_receive(:https_get) do |host, path, params, headers|
        headers["GData-Version"].should eq("3.0")
        headers["Authorization"].should eq("#{token_type} #{token}")
        self_response
      end
      gmail.should_receive(:https_get) do |host, path, params, headers|
        headers["GData-Version"].should eq("3.0")
        headers["Authorization"].should eq("#{token_type} #{token}")
        contacts_as_json
      end
      gmail.fetch_contacts_using_access_token token, token_type
      
      gmail.scope.should eq "https://www.googleapis.com/auth/contacts.readonly https://www.googleapis.com/auth/userinfo#email https://www.googleapis.com/auth/userinfo.profile"
      gmail_with_scope_args.scope.should eq "https://www.googleapis.com/auth/contacts.readonly https://www.googleapis.com/auth/userinfo#email https://www.googleapis.com/auth/userinfo.profile"
    end

    it "should correctly parse id, name, email, gender, birthday, profile picture and relation for 1st contact" do
      gmail.should_receive(:https_get)
      gmail.should_receive(:https_get).and_return(contacts_as_json)
      result = gmail.fetch_contacts_using_access_token token, token_type

      result.size.should be(2)
      result.first[:id].should eq('http://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/base/1')
      result.first[:first_name].should eq('Edward')
      result.first[:last_name].should eq('Bennet')
      result.first[:name].should eq("Edward Bennet")
      result.first[:email].should eq("bennet@gmail.com")
      result.first[:gender].should eq("male")
      result.first[:birthday].should eq({:day=>02, :month=>07, :year=>1954})
      result.first[:relation].should eq('father')
      result.first[:profile_picture].should eq("https://www.google.com/m8/feeds/photos/media/logged_in_user%40gmail.com/6b41d030b05abc?&access_token=token")
      result.first[:dates][0][:name].should eq("anniversary")
    end

    it "should correctly parse id, name, email, gender, birthday, profile picture, snailmail address, phone and relation for 2nd contact" do
      gmail.should_receive(:https_get)
      gmail.should_receive(:https_get).and_return(contacts_as_json)
      result = gmail.fetch_contacts_using_access_token token, token_type
      result.size.should be(2)
      result.last[:id].should eq('http://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/base/1')
      result.last[:first_name].should eq('Emilia')
      result.last[:last_name].should eq('Fox')
      result.last[:name].should eq("Emilia Fox")
      result.last[:email].should eq("emilia.fox@gmail.com")
      result.last[:gender].should eq("female")
      result.last[:birthday].should eq({:day=>10, :month=>02, :year=>1974})
      result.last[:profile_picture].should be_nil
      result.last[:relation].should eq('spouse')
      result.first[:address_1].should eq('1313 Trashview Court')
      result.first[:address_2].should eq('Apt. 13')
      result.first[:city].should eq('Nowheresville')
      result.first[:region].should eq('OK')
      result.first[:country].should eq('VA')
      result.first[:postcode].should eq('66666')
      result.first[:phone_number].should eq('653157688')
    end

    it "should correctly parse and set logged in user information" do
      gmail.should_receive(:https_get).and_return(self_response)
      gmail.should_receive(:https_get).and_return(contacts_as_json)

      gmail.fetch_contacts_using_access_token token, token_type

      user = gmail.instance_variable_get(:@env)["omnicontacts.user"]
      user.should_not be_nil
      user[:id].should eq("16482944006464829443")
      user[:first_name].should eq("Chris")
      user[:last_name].should eq("Johnson")
      user[:name].should eq("Chris Johnson")
      user[:email].should eq("chrisjohnson@gmail.com")
      user[:gender].should eq("male")
      user[:birthday].should eq({:day=>21, :month=>06, :year=>1982})
      user[:profile_picture].should eq("https://lh3.googleusercontent.com/-b8aFbTBM/AAAAAAI/IWA/vsek/photo.jpg")
    end
  end
end