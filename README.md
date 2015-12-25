# OmniContacts

Inspired by the popular OmniAuth, OmniContacts is a library that enables users of an application to import contacts
from their email or Facebook accounts. The email providers currently supported are Gmail, Yahoo and Hotmail.
OmniContacts is a Rack middleware, therefore you can use it with Rails, Sinatra and any other Rack-based framework.

OmniContacts uses the OAuth protocol to communicate with the contacts provider. Yahoo still uses OAuth 1.0, while
 Facebook, Gmail and Hotmail support OAuth 2.0.
In order to use OmniContacts, it is therefore necessary to first register your application with the provider and to obtain client_id and client_secret.

## Contribute!
Me (rubytastic) and the orginal author Diego don't actively use this code at the moment, anyone interested in maintaining and contributing to this codebase please write me up in a personal message ( rubytastic )
I try to merge pull requests in every once and a while but this code would benefit from someone actively use and contribute to it.

## Gem build updates
There is now a new gem build out which should address many issues people had when posting on the issue tracker. Please update to the latest GEM version if you have problems before posting new issues.


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
  importer :linkedin, "consumer_id", "consumer_secret", {:redirect_path => "/oauth2callback", :state => '<long_unique_string_value>'}
  importer :hotmail, "client_id", "client_secret"
  importer :facebook, "client_id", "client_secret"
end

```

Every importer expects `client_id` and `client_secret` as mandatory, while `:redirect_path` and `:ssl_ca_file` are optional (except linkedin - `state` arg  mandatory).
Since Yahoo implements the version 1.0 of the OAuth protocol, naming is slightly different. Instead of `:redirect_path` you should use `:callback_path` as key in the hash providing the optional parameters.
While `:ssl_ca_file` is optional, it is highly recommended to set it on production environments for obvious security reasons.
On the other hand it makes things much easier to leave the default value for `:redirect_path` and `:callback path`, the reason of which will be clear after reading the following section.

## Register your application

* For Gmail : [Google API Console](https://code.google.com/apis/console/)

* For Yahoo : [Yahoo Developer Network](https://developer.apps.yahoo.com/projects)

* For Hotmail : [Microsoft Developer Network](https://account.live.com/developers/applications/index)

* For Facebook : [Facebook Developers](https://developers.facebook.com/apps)

* For Linkedin : [Linkedin Developer Network](https://www.linkedin.com/secure/developer)


##### Note:
Please go through [MSDN](http://msdn.microsoft.com/en-us/library/cc287659.aspx) if above Hotmail link will not work.

## Integrating with your Application

To use the Gem you first need to redirect your users to `/contacts/:importer`, where `:importer` can be facebook, gmail, yahoo or hotmail.
No changes to `config/routes.rb` are needed for this step since OmniContacts will be listening on that path and redirect the user to the email provider's website in order to authorize your app to access his contact list.
Once that is done the user will be redirected back to your application, to the path specified in `:redirect_path` (or `:callback_path` for yahoo).
If nothing is specified the default value is `/contacts/:importer/callback` (e.g. `/contacts/yahoo/callback`). This makes things simpler and you can just add the following line to `config/routes.rb`:

```ruby
  match "/contacts/:importer/callback" => "your_controller#callback"
```

The list of contacts can be accessed via the `omnicontacts.contacts` key in the environment hash and it consists of a simple array of hashes.
The following table shows which fields are supported by which provider:

<table>
	<tr>
		<th>Provider</th>
		<th>:email</th>
		<th>:id</th>
		<th>:profile_picture</th>
		<th>:name</th>
		<th>:first_name</th>
		<th>:last_name</th>
		<th>:address_1</th>
		<th>:address_2</th>
		<th>:city</th>
		<th>:region</th>
		<th>:postcode</th>
		<th>:country</th>
		<th>:phone_number</th>
		<th>:birthday</th>
		<th>:gender</th>
		<th>:relation</th>
	</tr>
	<tr>
		<td>Gmail</td>
		<td>X</td>
		<td>X</td>
		<td></td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
	</tr>
	<tr>
		<td>Facebook</td>
		<td></td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
	</tr>
	<tr>
		<td>Yahoo</td>
		<td>X</td>
		<td>X</td>
		<td></td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td></td>
		<td></td>
		<td>X</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td>Hotmail</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td>X</td>
		<td>X</td>
		<td></td>
	</tr>
	<tr>
	    <td>Linkedin</td>
		<td></td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td>X</td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
		<td></td>
	<tr>
</table>

Obviously it may happen that some fields are blank even if supported by the provider in the case that the contact did not provide any information about them.

The information for the logged in user can also be accessed via 'omnicontacts.user' key in the environment hash. It consists of a simple hash which includes the same fields as above.

The following snippet shows how to simply print name and email of each contact, and also the the name of logged in user:
```ruby
def contacts_callback
  @contacts = request.env['omnicontacts.contacts']
  @user = request.env['omnicontacts.user']
  puts "List of contacts of #{@user[:name]} obtained from #{params[:importer]}:"
  @contacts.each do |contact|
    puts "Contact found: name => #{contact[:name]}, email => #{contact[:email]}"
  end
end
```

If the user does not authorize your application to access his/her contacts list, or any other inconvenience occurs, he/she is redirected to `/contacts/failure`. The query string will contain a parameter named `error_message` which specifies why the list of contacts could not be retrieved. `error_message` can have one of the following values: `not_authorized`, `timeout` and `internal_error`.

##  Tips and tricks

OmniContacts supports OAuth 1.0 and OAuth 2.0 token refresh, but for both it needs to persist data between requests. OmniContacts stores access tokens in the session. If you hit the 4KB cookie storage limit you better opt for the Memcache or the Active Record storage.

Gmail requires you to register the redirect_path on their website along with your application. Make sure to use the same value present in the configuration file, or `/contacts/gmail/callback` if using the default. Also make sure that your full url is used including "www" if your site redirects from the root domain. 

To configure the max number of contacts to download from Gmail, just add a max results parameter in your initializer:

```ruby
importer :gmail, "xxx", "yyy", :max_results => 1000
```

Yahoo requires you to configure the Permissions your application requires. Make sure to go the Yahoo website and to select Read permission for Contacts.

Hotmail presents a "peculiar" feature. Their API returns a Contact object which does not contain an e-mail field!
However, if the contact has either name, family name or both set to null, than there is a field called name which does contain the e-mail address.
This means that it may happen that an Hotmail contact does not contain the email field.

## Integration Testing

You can enable test mode like this:

```ruby
  OmniContacts.integration_test.enabled = true
```

In this way all requests to `/omnicontacts/provider` will be redirected automatically to `/omnicontacts/provider/callback`.

The `mock` method allows to configure per-provider the result to return:

```ruby
  OmniContacts.integration_test.mock(:provider_name, :email => "user@example.com")
```

You can either pass a single hash or an array of hashes. If you pass a string, an error will be triggered with subsequent redirect to `/contacts/failure?error_message=internal_error`

You can also pass a user to fill `omnicontacts.user` (optional)
```ruby
  OmniContacts.integration_test.mock(:provider_name, {:email => "contact@example.com"}, {:email => "user@example.com"})
```

Follows a full example of an integration test:

```ruby
  OmniContacts.integration_test.enabled = true
  OmniContacts.integration_test.mock(:gmail, :email => "user@example.com")
  visit '/contacts/gmail'
  page.should have_content("user@example.com")
```

## Working on localhost

Since Hotmail and Facebook do not allow the usage of `localhost` as redirect path for the authorization step, a workaround is to use `ngrok`.
This is really useful when you need someone, the contacts provider in this case, to access your locally running application using a unique url.

Install ngrok, download from:

https://ngrok.com/

https://github.com/inconshreveable/ngrok

Unzip the file
```bash
unzip /place/this/is/ngrok.zip
```
Start your application
```bash
$ rails server

=> Booting WEBrick
=> Rails 4.0.4 application starting in development on http://0.0.0.0:3000
```

In a new terminal window, start the tunnel and pass the port where your application is running:
```bash
./ngrok 3000
```

Check the output to see something like
```bash
ngrok                                                                                                                    (Ctrl+C to quit)

Tunnel Status                 online
Version                       1.6/1.5
Forwarding                    http://274101c1e.ngrok.com -> 127.0.0.1:3000
Forwarding                    https://274101c1e.ngrok.com -> 127.0.0.1:3000
Web Interface                 127.0.0.1:4040
# Conn                        0
Avg Conn Time                 0.00ms
```

This window will show all network transaction that your locally hosted application is processing.
Ngrok will process all of the requests and responses on your localhost. Visit:

```bash
http://123456789.ngrok.com # replace 123456789 with your instance
```

## Example application

Thanks to @sonianand11, you can find a full example of a Rails application using OmniContacts at: https://github.com/sonianand11/omnicontacts_example

## Thanks

As already mentioned above, a special thanks goes to @sonianand11 for implementing an example app.
Thanks also to @asmatameem for her huge contribution. She indeed added support for Facebook and for many fields which were missing before.

## License

Copyright (c) 2012-2013 Diego81

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
