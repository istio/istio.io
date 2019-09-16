---
title: Can I run Casandra inside an Istio mesh?
description: How to run Cassandra with Istio.
weight: 50
keywords: [cassandra]
---

The short answer is yes, Cassandra can run inside an Istio mesh.

By default, Cassandra broadcasts the address it uses for binding
(accepting connections) to other Cassandra nodes as its address. This
is usually the pod IP address and works fine without a service
mesh. However, with a service mesh this configuration does not
work. Istio and other service meshes require the `localhost`
(`127.0.0.1`) to be the address for binding.

## Cassandra Configuration

There are two configuration parameters to pay attention to:
[`listen_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#listen-address)
and
[`broadcast_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#broadcast-address). For
running Cassandra in an Istio mesh they need to be set appropriately.
The `listen_address` parameter should be set to `127.0.0.1` and the
`broadcast_address` parameter should be set to the pod IP address.

These configuration parameters are defined in `cassandra.yaml` in the
Cassandra configuration directory (e.g. `/etc/cassandra`).  There are
various startup scripts (and yaml files) used for starting Cassandra
and care should be given to how these parameters are set by these
scripts. As an example, an script used to configure and start
Cassandra uses the value of the environment variable
`CASSANDRA_LISTEN_ADDRESS` for setting `listen_address`.

## Service Definition

Another issue to keep in mind is having ports specified in the
Cassandra's headless service as shown below:

{{< text yaml>}}
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cassandra
  name: cassandra
spec:
  clusterIP: None
  ports:
    - port: 7000
      name: intra-node
    - port: 7001
      name: intra-node-tls
    - port: 7199
      name: jmx
    - port: 9042
      name: cql
  selector:
    app: cassandra
{{< /text >}}
