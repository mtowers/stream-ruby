# Realself::Stream [![Circle CI](https://circleci.com/gh/RealSelf/stream-ruby.svg?style=svg&circle-token=9bee1e8453fa503ca91bbfa034cdbfd8ebb68a66)](https://circleci.com/gh/RealSelf/stream-ruby) [![Coverage Status](https://coveralls.io/repos/github/RealSelf/stream-ruby/badge.svg?branch=master)](https://coveralls.io/github/RealSelf/stream-ruby?branch=master)

[Documentation](https://github.com/mtowers/stream-ruby/wiki)

[Sample Stream Service](https://github.com/mtowers/sample-stream-service)

## Installation

Add this line to your application's Gemfile:

    gem 'realself-stream', '~> [version]', :git => 'ssh://git@github.com/RealSelf/stream-ruby.git'

And then execute:

    $ bundle install


## Usage

#### Running Tests
The preferred method for running tests is via `rake` tasks.

```bash
# run all integration and unit tests
$ bundle exec rake test

# run integration tests only
$ bundle exec rake test:integration

# run unit tests only
$ bundle exec rake test:unit

# skip TTL test, while running all others
$ SKIP_TTL_TESTS=true bundle exec rake test
```

* Integration tests assume MongoDB ``~>2.6.0` is running locally and listening on port `27017`.
* `bundle exec rspec` will run all integration and unit tests
* The TTL integration test must allow the TTL to expire to compleate all tests.  To skip waiiting for the timeout, set the `SKIP_TTL_TESTS` environment variable to `true`.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
