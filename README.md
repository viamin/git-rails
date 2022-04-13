# Git::Rails

`git_rails` is a command line tool for extracting some useful rails-related files from your git working directory.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'git_rails', require: false
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install git_rails

## Usage

Find a full list of command line options by running `git-rails --help`

Some useful commands:
```
git-rails --cached
```
will output a list of files that are staged in the git working directory.

```
git-rails --unstaged-only
```
will output a list of files that are changed but not staged in the current git working directory.

You can combine options to run a command on the output files:
```
git-rails --unstaged-only --run-rspec
```
will run the list of unstaged files through rspec (matching `.rb` files to `_spec.rb` files)

```
git-rails --cached --run-rubocop-autocorrect
```
will run staged files through rubocop with the `--safe-auto-correct` option.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/viamin/git_rails.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
