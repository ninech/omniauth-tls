# OmniAuth TLS

This is an [OmniAuth][omniauth-home] strategy, that allows your users to identify with TLS client certificates.
This strategy relies on Apache HTTP or Nginx (or probably any other web sever) to do the TLS certificate verification for us.
We only check the result of the verification.  

[omniauth-home]: https://github.com/omniauth/omniauth

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-tls'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-tls

## Usage

Use it like any other Omniauth strategy:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :tls
end
```

### Configuration Options

You can overwrite the default for the following variables like so:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :tls, variable: 'new_value'
end
```

* `value_source` - How to get information from the upstream HTTP daemon. Allowed: `:http` and `:env`. _Default: `:env`_
* `validity_end_variable` - The name of the variable, which contains the validity end date of the client certificate. _Default: `SSL_CLIENT_V_END`_
* `dn_variable` – The name of the variable, which contains the DN information. _Default: `SSL_CLIENT_S_DN`_
* `dn_email_field` – Which part of the DN contains the email address. _Default: `emailAddress`_
* `dn_name_field` – Which part of the DN contains the email address. _Default: `CN`_
* `validation_success_variable` – The name of the variable, which contains information about the client certificate verification. _Default: `SSL_CLIENT_VERIFY`_
* `validation_success_value` – The value which indicates a successful client certificate verification. _Default: `SUCCESS`_ 
* `verify_validation_success_state` – Whether to check if the verification was successful or not. _Default: `true`_
* `use_email_as_uid` – Whether to use the email (see `dn_email_field` above) as the OmniAuth UID.
  If set to `false`, then the full DN of the certificate is used as UID. _Default: `false` (i.e. use DN by default)_ 

### Extra Information

As part of OmniAuth's extra hash you get access to:

* `dn` – The full DN as received from the upstream server.
* `v_end` – The date / time when the certificate is valid for the last time. See `validity_end_variable` above.

### Apache HTTPD Config

Add the following bits to your existing VServer, which already has TLS properly configured.

```
SSLCACertificateFile /etc/ssl/certs/ca/certs/ca.crt
SSLCARevocationFile /etc/ssl/ca/private/ca.crl

<Location /auth/tls/callback> 
  SSLOptions +StdEnvVars
  SSLVerifyClient require
</Location>
```

This should do the trick.

### Nginx Config

In Nginx, at least using with Pushion Passenger, you can only pass per-request values as HTTP headers.
Therefore you need to change the `value_source` to `:http` and you need to adjust all the variable names:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :tls, value_source: :http
end
``` 

```
server {
  listen 443 ssl;
  
  ssl_client_certificate /etc/ssl/ca/certs/ca.crt;
  ssl_crl /etc/ssl/ca/private/ca.crl;
  ssl_verify_client on
  
  location / {
    ...
    
    passenger_set_header X-SSL-CLIENT-VERIFY $ssl_client_verify;
    passenger_set_header X-SSL-CLIENT-S-DN $ssl_client_s_dn;
    passenger_set_header X-SSL-CLIENT-V-END $ssl_client_v_end;
  } 
}
```

With Nginx it does not seem possible to authenticate only a certain path, like it is with Apache's HTTPD.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `VERSION`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Developing locally

In the `/webapp` folder, there is a simple Rails application, which has _devise_ and _omniauth_ and _omniauth-tls_ preconfigured.
Then there's a Dockerfile which builds a runtime based on Phusion Passenger and Nginx.
The nginx configuration is in `/docker/localhost.conf`.
In `/docker/tls`, there are certificates which are configured. The `client.p12` has a password, which is `a`.

```bash
# launch the container
docker-compose up

# run a query using the client certificate
curl -Lv https://localhost:8443/auth/tls/callback -k -E docker/tls/client.p12:a
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ninech/omniauth-tls.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
