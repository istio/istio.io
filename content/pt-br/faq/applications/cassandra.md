---
title: Can I run Casandra inside an Istio mesh?
description: How to run Cassandra with Istio.
weight: 50
keywords: [cassandra]
---

By default, Cassandra broadcasts the address it uses for binding
(accepting connections) to other Cassandra nodes as its address. This
is usually the pod IP address and works fine without a service
mesh. However, with a service mesh this configuration does not
work. Istio and other service meshes require `localhost`
(`127.0.0.1`) to be the address for binding.

There are two configuration parameters to pay attention to:
[`listen_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#listen-address)
and
[`broadcast_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#broadcast-address). For
running Cassandra in an Istio mesh,
the `listen_address` parameter should be set to `127.0.0.1` and the
`broadcast_address` parameter should be set to the pod IP address.

These configuration parameters are defined in `cassandra.yaml` in the
Cassandra configuration directory (e.g. `/etc/cassandra`).  There are
various startup scripts (and yaml files) used for starting Cassandra
and care should be given to how these parameters are set by these
scripts. For example, some scripts used to configure and start
Cassandra use the value of the environment variable
`CASSANDRA_LISTEN_ADDRESS` for setting `listen_address`.
