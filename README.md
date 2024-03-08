# SorbetErb

`sorbet_erb` parses Rails ERB files and extracts the Ruby code so that
you can run Sorbet typechecking over them. This assumes you're already
using Sorbet and Tapioca together to generate RBI.

Currently this only supports Rails applications since it generates Ruby
scoped with a Rails `ApplicationController`. Feel free to file an issue
if you're interested in using this in other contexts.

### Limitations
- You must manually specify extra_includes that aren't covered by Tapioca
- Does not handle ViewComponent methods (e.g. `with_*`)
- Rails partials (files beginning with `_`) must use strict locals.
  sorbet_erb will skip them if there are no strict locals defined.
- local_assigns are not supported. Use strict locals instead.

## Installation

This gem isn't published to RubyGems yet, so you need to depend
directly on the git repository:

```
gem 'sorbet_enum', git: 'https://github.com/franklinhu/sorbet_enum'
```

After installing the gem, run `bundle binstubs sorbet_erb` to install
a helper script under `bin/sorbet_erb`.

## Usage

```
bin/sorbet_erb input_dir output_dir
```

You'll most likely want to pass in your Rails app directory as input
and use `sorbet/erb` as your output directory. Don't forget to add
`sorbet/erb` to your `.gitignore`.

```
bin/sorbet_erb ./app ./sorbet/erb
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/franklinhu/sorbet_erb.
