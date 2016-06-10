# Emque Consuming CHANGELOG

- [Remove double ack when consuming a message and ending up in an error state. This was causing consumers to die silently.](https://github.com/emque/emque-consuming/pull/59) 1.2.1
- [Add in the ability to retry errors and back off with an exponential delay](https://github.com/emque/emque-consuming/pull/55) 1.2.0
- [Add in a configuration option to disable auto shutdown on reaching the error limit](https://github.com/emque/emque-consuming/pull/58) 1.1.3

## 1.0.0.beta4

### BREAKING CHANGE - New Queue Names
Applications updating to this version will have new queue names in RabbitMQ.
After starting up, messages will need to be manually moved
from the old queue to the new one.

### Failed Message Routing
Messages that are not acknowledged due to a consumer error will now be routed
into a `service_name.error` queue. These can then be inspected and be discarded,
purged, or manually moved back to the primary queue for re-processing.
