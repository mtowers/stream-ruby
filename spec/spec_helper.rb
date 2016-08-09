require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter]

SimpleCov.start do
  add_filter '/spec/'
end
Coveralls.wear!

require 'rubygems'
require 'rspec'

require 'pry-byebug'
require 'mongo'
require 'realself/stream'
require 'realself/handler'
require 'realself/feed'
require 'realself/feed/feed_error'
require 'realself/graph/follow'
require 'realself/daemon'
require 'realself/stream/digest/digest'

require_relative './helpers'
require_relative './integration/integration_helper' unless ARGV[0] && ARGV[0].match(/spec\/unit/)
require_relative './integration/realself/feed/getable_shared_examples'
require_relative './integration/realself/feed/stateful_shared_examples'
require_relative './integration/realself/feed/insertable_shared_examples'
require_relative './integration/realself/feed/redactable_shared_examples'
require_relative './integration/realself/feed/unread_countable_shared_examples'

require_relative './integration/realself/feed/state/bookmarkable_shared_examples'
require_relative './integration/realself/feed/state/sessioned_shared_examples'
require_relative './integration/realself/feed/state/unread_countable_shared_examples'

require_relative './unit/realself/stream/digest/digest_spec'

