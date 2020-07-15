---
title: VirtualServiceDestinationPortSelectorRequired
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a virtual service routes to a service with more than one port exposed, but does not specify which one to use. This ambiguity can lead to undefined behavior.

To fix, add a `port` to the virtual service [Destination](/docs/reference/config/networking/virtual-service/#Destination) to disambiguate which service port should be routed to.
