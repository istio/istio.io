---
title: Can I run Casandra inside an Istio mesh?
description: How to run Cassandra with Istio.
weight: 50
keywords: [cassandra]
---

The sort answer is yes, Cassandra can run inside an Istio mesh.

1. Cassandra Configuration

There are two configuration parameters to pay attention to:
[`listen_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#listen-address)
and
[`broadcast_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#broadcast-address). For
running Cassandra in an Istio mesh they need to be set appropriately.
The `listen_address` parameter should be set to `127.0.0.1` and the
`broadcast_address` parameter should be set to the pod IP address.

These configuration parameters are defined in `cassandra.yaml` in the
Cassandra configuration directory (e.g. `/etc/cassandra`).  There are
various startup scripts (and yaml files) used for starting Cassandra and care
should be given to how these parameters are set by these scripts. As an example, an
script used to configure and start Cassandra uses the value of the environment variable
`CASSANDRA_LISTEN_ADDRESS` for setting `listen_address`.

1. Service Definition

Another issue to keep in mind is having ports specified in the
Cassandra's headless service as shown below:

{{< text plain >}}
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cassandra
  name: cassandra
  namespace: cassandra-istio
spec:
  clusterIP: None
  ports:
  - name: intra-node
    port: 7000
  - port: 7001
    name: tls-intra-node
  - port: 7199
    name: jmx
  - port: 9042
    name: cql
  selector:
    app: cassandra
{{< /text >}}

1. Using MTLS

MTLS can be enabled or disabled for Cassandra as it is done for any
other service in Istio. No special configuration is required.
