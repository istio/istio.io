---
title: Tcpdump Limitations
description: Limitations for using Tcpdump in pods.
weight: 99
---

Tcpdump doesn't work in the sidecar pod - the container doesn't run as root. However any other container in the same pod will see all the packets, since the
network namespace is shared. `iptables` will also see the pod-wide configuration.

Communication between Envoy and the app happens on 127.0.0.1, and is not encrypted.
