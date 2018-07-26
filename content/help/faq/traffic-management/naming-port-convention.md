---
title: What is the naming convention for port name inside my application deployment file?
weight: 50
---

Named ports: Service ports must be named.

The port names must be of the form `protocol`-`suffix` with http, http2, grpc, mongo, or redis as the `protocol` in order to take advantage of Istio’s routing features.

For example, `name: http2-foo` or `name: http` are valid port names, but `name: http2foo` is not. If the port name does not begin with a recognized prefix or if the port is unnamed, traffic on the port will be treated as plain TCP traffic (unless the port explicitly uses Protocol: UDP to signify a UDP port).

