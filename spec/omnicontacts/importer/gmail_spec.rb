require "spec_helper"
require "omnicontacts/importer/gmail"

describe OmniContacts::Importer::Gmail do

  let(:gmail) { OmniContacts::Importer::Gmail.new({}, "client_id", "client_secret") }

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
            {"rel":"alternate","type":"text/html","href":"http://www.google.com/"},
            {"rel":"http://schemas.google.com/g/2005#feed","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full"},
            {"rel":"http://schemas.google.com/g/2005#post","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full"},
            {"rel":"http://schemas.google.com/g/2005#batch","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/batch"},
            {"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full?alt\u003djson\u0026max-results\u003d1"},
            {"rel":"next","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full?alt\u003djson\u0026start-index\u003d2\u0026max-results\u003d1"}
          ],
          "author":[{"name":{"$t":"Asma"},"email":{"$t":"logged_in_user@gmail.com"}}],
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
              {"rel":"http://schemas.google.com/contacts/2008/rel#photo","type":"image/*","href":"https://www.google.com/m8/feeds/photos/media/logged_in_user%40gmail.com/1"},
              {"rel":"self","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/1"},
              {"rel":"edit","type":"application/atom+xml","href":"https://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/full/1"}
            ],
            "gd$name":{
              "gd$fullName":{"$t":"Edward Bennet"},
              "gd$givenName":{"$t":"Edward"},
              "gd$familyName":{"$t":"Bennet"}
            },
            "gContact$birthday":{"when":"1954-07-02"},
            "gContact$relation":{"rel":"father"},
            "gContact$gender":{"value":"male"},
            "gd$email":[{"rel":"http://schemas.google.com/g/2005#other","address":"bennet@gmail.com","primary":"true"}],
            "gContact$groupMembershipInfo":[{"deleted":"false","href":"http://www.google.com/m8/feeds/groups/logged_in_user%40gmail.com/base/6"}]
          }]
        }
      }'
  }

  describe "fetch_contacts_using_access_token" do
    let(:token) { "token" }
    let(:token_type) { "token_type" }

    it "should request the contacts by specifying version and code in the http headers" do
      gmail.should_receive(:https_get) do |host, path, params, headers|
        headers["GData-Version"].should eq("3.0")
        headers["Authorization"].should eq("#{token_type} #{token}")
        contacts_as_json
      end
      gmail.fetch_contacts_using_access_token token, token_type
    end

    it "should correctly parse id, name,email,gender, birthday, image source and relation" do
      gmail.should_receive(:https_get).and_return(contacts_as_json)
      result = gmail.fetch_contacts_using_access_token token, token_type
      result.size.should be(1)
      result.first[:id].should eq('http://www.google.com/m8/feeds/contacts/logged_in_user%40gmail.com/base/1')
      result.first[:first_name].should eq('Edward')
      result.first[:last_name].should eq('Bennet')
      result.first[:name].should eq("Edward Bennet")
      result.first[:email].should eq("bennet@gmail.com")
      result.first[:gender].should eq("male")
      result.first[:birthday].should eq({:day=>02, :month=>07, :year=>1954})
      result.first[:relation].should eq('father')
    end

  end
end
