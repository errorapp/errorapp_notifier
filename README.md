ErrorApp
===============

This is the notifier gem for integrating apps with ErrorApp.

When an exception occurs, ErrorappNotifier will POST the relevant data to the ErrorApp server specified in your environment.

## Rails Installation

Add the ErrorappNotifier gem to your gemfile:

```ruby
gem 'errorapp_notifier'
```
Install the gem
```ruby
bundle install
```
Then run the our generator which will create a initializer file
`errorapp_notifier.rb`
```ruby
rails generate errorapp_notifier --api_key <Your Project Api Key>
```

OR you can manually create initializer file and put below code snippet in that file
```ruby
ErrorappNotifier.configure do|config|
  config.api_key = 'api key'
end
```

##Testing Integration

To test that errorapp_notifier is properly installed run below rake task
```ruby
rake errorapp_notifier:test_exception
```
A test exception will be sent to your ErrorApp dashboard if everything is configured correctly.

## Contributing

1. Fork it.
2. Create a topic branch `git checkout -b my_branch`
3. Commit your changes `git commit -am "Boom"`
3. Push to your branch `git push origin my_branch`
4. Send a [pull request](https://github.com/errorapp/errorapp_notifier/pulls)

## Credits

Idea from various Apps.

Thanks to

1. Airbrake
2. Exceptional

## License

ErrorApp is Copyright 2014 © ErrorApp. It is free software, and
may be redistributed under the terms specified in the MIT-LICENSE file.
