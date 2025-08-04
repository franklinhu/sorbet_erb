# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in sorbet_erb.gemspec
gemspec

group :development, :test do
  gem 'minitest', '~> 5.16'
  gem 'pry-byebug', '~> 3.10.1'
  gem 'rake', '~> 13.0'
  gem 'rubocop', '~> 1.21'

  # Runtime dependencies for Tapioca compiler
  gem 'rails', '~> 7.1.3'
  gem 'view_component', '~> 3.12.1'

  gem 'sorbet-static-and-runtime', '~> 0.5.11340'
end
