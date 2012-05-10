# OmniContacts

Inspired by the popular OmniAuth, OmniContacts is a library that enables users of an application to import contacts from their email accounts.
The current version allows to import contacts from the three most popular web email providers: Gmail, Yahoo and Hotmail.
OmniContacts is a Rack middleware, therefore you can use it with Rails, Sinatra and with any other Rack-based framework.

OmniContacts uses the OAuth protocol to communicate with the contacts provider. Yahoo still uses OAuth 1.0, while both Gmail and Hotmail support OAuth 2.0.
In order to use OmniContacts, it is therefore necessary to first register your application with the providers you want to use and to obtain client_id and client_secret.

## Usage

Add OmniContacts as a dependency:

```ruby
gem "omnicontacts"

```

As for OmniAuth, there is a Builder facilitating the usage of multiple contacts importers. In the case of a Rails application, the following code could be placed at `config/initializers/omnicontacts.rb`:

```ruby
require "omnicontacts"

Rails.application.middleware.use OmniContacts::Builder do
  importer :gmail, "client_id", "client_secret", {:redirect_path => "/oauth2callback", :ssl_ca_file => "/etc/ssl/certs/curl-ca-bundle.crt"}
  importer :yahoo, "consumer_id", "consumer_secret", {:callback_path => '/callback'}
  importer :hotmail, "client_id", "client_secret"
end

```

Every importer expects `client_id` and `client_secret` as mandatory, while `:redirect_path` and `:ssl_ca_file` are optional.
Since Yahoo implements the version 1.0 of the OAuth protocol, naming is slightly different. Instead of `:redirect_path` you should use `:callback_path` as key in the hash providing the optional parameters.
While `:ssl_ca_file` is optional, it is highly recommended to set it on production environments for obvious security reasons.
On the other hand it makes things much easier to leave the default value for `:redirect_path` and `:callback path`, the reason of which will be clear after reading the following section.

## Integrating with your Application

To use the Gem you first need to redirect your users to `/contacts/:importer`, where `:importer` can be google, yahoo or hotmail. 
No changes to `config/routes.rb` are needed for this step since OmniContacts will be listening on that path and redirect the user to the email provider's website in order to authorize your app to access his contact list.
Once that is done the user will be redirected back to your application, to the path specified in `:redirect_path` (or `:callback_path` for yahoo).
If nothing is specified the default value is `/contacts/:importer/callback` (e.g. `/contacts/yahoo/callback`). This makes things simpler and you can just add the following line to `config/routes.rb`:

```ruby
  match "/contacts/:importer/callback" => "your_controller#callback"
```

The list of contacts can be accessed via the `omnicontacts.contacts` key in the environment hash. It is a simple array of hashes. Each hash has two keys: `:email` and `:name`, containing the email and the name of the contact respectively.

```ruby
def contacts_callback
  @contacts = request.env['omnicontacts.contacts']
  puts "List of contacts obtained from #{params[:importer]}:"
  @contacts.each do |contact|
    puts "Contact found: name => #{contact[:name]}, email => #{contact[:email]}"
  end
end
```

If the user does not authorize your application to access his/her contacts list, or any other inconvenience occurs, he/she is redirected to `/contacts/failure`. The query string will contain a parameter named `error_message` which specifies why the list of contacts could not be retrieved. `error_message` can have one of the following values: `not_authorized`, `timeout` and `internal_error`.

##  Tips and tricks

OmniContacts supports OAuth 1.0 and OAuth 2.0 token refresh, but for both it needs to persist data between requests. OmniContacts stores access tokens in the session. If you hit the 4KB cookie storage limit you better opt for the Memcache or the Active Record storage.

Gmail requires you to register the redirect_path on their website along with your application. Make sure to use the same value present in the configuration file, or `/contacts/gmail/callback` if using the default.

Yahoo requires you to configure the Permissions your application requires. Make sure to go the Yahoo website and to select Read permission for Contacts.

Hotmail does not accept requests from localhost. This can be quite annoying during development, but unfortunately this is the way it is.
Hotmail presents another "peculiar" feature. Their API returns a Contact object, which does not contain an e-mail field! However, if the contact has either name, family name or both set to null, than there is a field called name which does contain the e-mail address. To summarize, a  Hotmail contact will only be returned if the name field contains a valid e-mail address, otherwise it will be skipped. Another consequence is that OmniContacts can provide contacts with only the `:email` key set.

## License

Copyright (c) 2012 Diego81

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
