[ ![Codeship Status for
teamsnap/emque-consuming](https://www.codeship.io/projects/83d08620-2023-0132-2bcd-1a9cd91404f6/status)](https://www.codeship.io/projects/35892)

# Emque::Consuming

Emque Consuming is a Ruby application framework that includes everything needed
to create and run services capable of consuming messages from a message broker
in a Pub/sub architecture.  Messages can be produced with the
[emque-producing](https://github.com/teamsnap/emque-producing) library.

## Adapters

We currently only support RabbitMQ. If you would like to add your own adapter,
take a look at [the adapters directory](https://github.com/teamsnap/emque-consuming/tree/socket-control/lib/emque/consuming/adapters).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "emque-consuming", :git => "https://github.com/teamsnap/emque-consuming"
# make sure you have bunny for rabbitmq unless you're using a custom adapter
gem "bunny", "~> 1.4.1"

```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install emque-consuming

## Setup

### Easy

Using the `new` generator is the easiest way to get up and running quickly.

```
emque <options> new name
```

This command will create a directory "name" with barebones directories and files
you'll need to get started. You can also use the following command line options
to customize your service's configuration. Options will be added to the
application.rb file generated.

```
emque <options> (start|stop|new|console|help) <name (new only)>
    # ...
    -S, --socket PATH                PATH to the service's unix socket
    -b, --bind IP:PORT               IP & port for the http status service to listen on.
    # ...
    -e, --error-limit N              Set the max errors before service suicide
    -s, --status                     Run the http status service
    -x, --error-expiration SECONDS   Expire errors after SECONDS
        --app-name NAME              Run the application as NAME
    # ...
```

### Custom

Configure Emque::Consuming in your application.rb file. Here is an example:

```ruby
# config/application.rb
require "emque/consuming"

module Example
  class Application
    include Emque::Consuming::Application

    initialize_core!

    config.set_adapter(:rabbit_mq)
  end
end
```

You'll also want to set up a routes.rb file:

```ruby
# config/routes.rb

Example::Application.router.map do
  topic "events" => EventsConsumer do
    map "events.new" => "new_event"
    # ...
  end

  # ...
end
```

and a consumer for each topic:

```ruby
# service/consumers/events_consumer.rb

class EventsConsumer
  include Emque::Consuming.consumer

  def new_event(message)
    # NOTE: message is an immutable [Virtus](https://github.com/solnic/virtus) Value Object.
    # Check it out here: https://github.com/teamsnap/emque-consuming/blob/master/lib/emque/consuming/message.rb

    # You don't have to use (pipe)[https://github.com/teamsnap/emque-consuming/blob/master/lib/emque/consuming/consumer/common.rb#L23], be we love it!
    pipe(message, :through => [
      :shared_action, :do_something_with_new_event
    ])
  end

  private

  def shared_action(message)
    # ...
  end

  def do_something_with_new_event(message)
    # ...
  end
end
```

## Usage

Emque::Consuming provides a command line interface:

```
$ bundle exec emque help

emque <options> (start|stop|new|console|help) <name (new only)>
    -P, --pidfile PATH               Store pid in PATH
    -S, --socket PATH                PATH to the service's unix socket
    -b, --bind IP:PORT               IP & port for the http status service to listen on.
    -d, --daemon                     Daemonize the service
    -e, --error-limit N              Set the max errors before service suicide
    -s, --status                     Run the http status service
    -x, --error-expiration SECONDS   Expire errors after SECONDS
        --app-name NAME              Run the application as NAME
        --env (ex. production)       Set the application environment, overrides EMQUE_ENV
```

and a series of rake commands:

```
$ bundle exec rake -T

rake emque:configuration        # Show the current configuration of a running instance (accepts SOCKET)
rake emque:console              # Start a pry console
rake emque:errors:clear         # Clear all outstanding errors (accepts SOCKET)
rake emque:errors:expire_after  # Change the number of seconds to SECONDS before future errors expire (accepts SOCKET)
rake emque:errors:limit:down    # Decrease the error limit (accepts SOCKET)
rake emque:errors:limit:up      # Increase the error limit (accepts SOCKET)
rake emque:restart              # Restart the workers inside a running instance (does not reload code; accepts SOCKET)
rake emque:routes               # Show the available routes
rake emque:start                # Start a new instance (accepts PIDFILE, DAEMON)
rake emque:status               # Show the current status of a running instance (accepts SOCKET)
rake emque:stop                 # Stop a running instance (accepts SOCKET)
```

To use the rake commands, add the following line to your application's Rakefile:

```ruby
require "emque/consuming/tasks"
```

## Tests

Testing is a bit sparse at the moment, but we're working on it.

To run tests...

```
bundle exec rspec
```

## Contributing

FIRST: Read our style guides at https://github.com/teamsnap/guides/tree/master/ruby

1. Fork it ( http://github.com/teamsnap/emque-consuming/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
