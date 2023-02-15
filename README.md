# Activerecord::PedantMysql2

[![Build Status](https://secure.travis-ci.org/Shopify/activerecord-pedantmysql2-adapter.png)](http://travis-ci.org/Shopify/activerecord-pedantmysql2-adapter)
[![Code Climate](https://codeclimate.com/github/Shopify/activerecord-pedantmysql2-adapter.png)](https://codeclimate.com/github/Shopify/activerecord-pedantmysql2-adapter)
[![Coverage Status](https://coveralls.io/repos/Shopify/activerecord-pedantmysql2-adapter/badge.png)](https://coveralls.io/r/Shopify/activerecord-pedantmysql2-adapter)
[![Gem Version](https://badge.fury.io/rb/activerecord-pedantmysql2-adapter.png)](http://badge.fury.io/rb/activerecord-pedantmysql2-adapter)

**This gem is deprecated as of Active Record 7.1, and will be archived once a subsequent version of Active Record is released.**

SQL warning reporting is available on all MySQL Active Record adapter classes as of version 7.1.
Please migrate to the [upstream API](https://edgeguides.rubyonrails.org/configuring.html#config-active-record-db-warnings-action).

---

ActiveRecord adapter for MySQL that report warnings.

The main usage is to progressively identify and fix MySQL warnings generated by legacy rails applications, and ultimately enable strict mode.

Alternatively it can be used to treat all MySQL warnings as errors.

## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-pedantmysql2-adapter'

And then execute:

    $ bundle

Finally in your `database.yml`:

    adapter: pedant_mysql2

Or if you're using `DATABASE_URL` or the url key in `database.yml`, you can use the `pedant-mysql2` URL scheme:

    url: pedant-mysql2://host/database

## Usage

By default it will raise warnings as errors. But you can define any behaviour yourself in an initializer.

You can report them to your exception tracker:

```ruby
  PedantMysql2.on_warning = lambda { |warning| Airbrake.notify(warning) }
```

or totally silence them:

```ruby
  PedantMysql2.silence_warnings!
```

and to restore it to raising warnings as errors:

```ruby
  PedantMysql2.raise_warnings!
```

You can easily whitelist some types of warnings:

```ruby
PedantMysql2.ignore(/Some warning I don't care about/i)
```

If you want to silence warnings for a limited scope, you can capture the warnings:

```ruby
warnings = PedantMysql2.capture_warnings do
  # perform query that may raise an error you want to stifle
end
 ```

## Thread-safe

This gem is tested to be thread safe with a couple known exceptions.

`PedantMysql2.ignore` is not thread safe and should only be called during initialization of your app. Changing this within a thread while another is updating it could be problematic.
`PedantMysql2.on_warning=` is not thread safe, this should also be called only during initialization.

If you find any other parts that are not thread-safe, please create an issue or PR.

## Development

Setting up the development environment is very straightforward. In order to keep the test
as simple as possible we rely on your MySQL database to have a `travis` user and a
`pedant_mysql2_test` database.

You can set this up easily using the following commands as your `root` MySQL user:

```
CREATE USER 'travis'@'localhost';
CREATE DATABASE pedant_mysql2_test;
GRANT ALL PRIVILEGES ON pedant_mysql2_test.* TO 'travis'@'localhost';
```

## Contributing

1. Fork it ( http://github.com/Shopify/activerecord-pedantmysql2-adapter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
