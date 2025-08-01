# frozen_string_literal: true

require_relative 'lib/sorbet_erb/version'

Gem::Specification.new do |spec|
  spec.name = 'sorbet_erb'
  spec.version = SorbetErb::VERSION
  spec.authors = ['Franklin Hu']
  spec.email = ['franklin@thisisfranklin.com']

  spec.summary = 'Extracts Ruby code from ERB files for Sorbet'
  spec.description = 'Extracts Ruby code from ERB files so you can run Sorbet over them'
  spec.homepage = 'https://github.com/franklinhu/sorbet_erb'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'better_html', '~> 2.1.1'
  spec.add_dependency 'psych'
  spec.add_dependency 'tapioca', '~> 0.17.1'
end
