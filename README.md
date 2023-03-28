# SlackbotLite

Easy to build Slackbot.

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add slackbot_lite
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install slackbot_lite
```

## Usage

```ruby
require 'slackbot_lite'

app_token = '...'
logger = Logger.new($stdout)
client = SlackbotLite.new(app_token, logger: logger)
return unless client.open(debug_reconnects: true)

client.each_payload do |payload|
  text = payload.dig(:event, :text)
  puts text
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gunyoki/slackbot_lite .

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
