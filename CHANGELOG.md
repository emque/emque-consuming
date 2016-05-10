# Emque Consuming CHANGELOG

- [Add in a configuration option to disable auto shutdown on reaching the error limit](https://github.com/emque/emque-consuming/pull/58) 1.0.1.beta4

## 1.0.0.beta4 — (unreleased)

### BREAKING CHANGE - New Queue Names
Applications updating to this version will have new queue names in RabbitMQ.
After starting up, messages will need to be manually moved
from the old queue to the new one.

### Failed Message Routing
Messages that are not acknolwedged due to a consumer error will now be routed
into a `service_name.error` queue. These can then be inspected and be discarded,
purged, or manually moved back to the primary queue for re-processing.
