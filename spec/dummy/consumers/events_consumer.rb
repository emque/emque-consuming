class EventsConsumer
  include Emque::Consuming.consumer

  def new_event(message)
  end
end
