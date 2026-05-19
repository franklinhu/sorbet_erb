# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in sorbet_erb.gemspec
gemspec

group :development, :test do
  gem 'minitest', '~> 6.0'
  gem 'pry-byebug', '~> 3.10.1'
  gem 'rake', '~> 13.0'
  gem 'rubocop', '~> 1.21'
  gem 'rubocop-sorbet', '~> 0.10.1'

  # Before Ruby 4, ostruct was included as part of stdlib, and
  # some gems still assume it is there
  # TODO: remove only we drop Ruby 3.x compatibility
  gem 'ostruct'
end
