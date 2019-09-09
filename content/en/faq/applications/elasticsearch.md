---
title: Can I run Elasticsearch Configuration inside an Istio mesh?
description: Elasticsearch configuration required for use with Istio
weight: 50
keywords: [elasticsearch]
---

The short answer is yes, Elasticsearch can run inside an Istio mesh
with default configuration settings.

1. Elasticsearch Configuration

There are two Elasticsearch configuration parameters that need to be
set appropriately for running Elasticsearch with Istio:
`network.bind_host` and `network.publish_host`.  By default, these
parameters are set to the `network.host` parameter. If this parameter
is set to `0.0.0.0`, Elasticsearch will most likely pick up the pod IP
as the publishing address and therefore no additional configuration is
needed.

With some configurations, Elasticsearch can work correctly
without a service mesh while failing to work with a service mesh.  A
configuration in which the `network.host` parameter is set to
the pod IP is such a configuration. In this case, `network.bind_host`
gets set to the pod IP. This configuration will not work with Istio.

In cases where Elasticsearch dose not pick the correct
addresses by default, for example when the host has multiple IP
addresses, the `network.publish_host` and `network.bind_host`
parameter should be set to the desired IP addresses explicitly.

In order to run Elasticsearch with Istio one should either use the
default configuration or explicitly set the `network.bind_host` to
`0.0.0.0` or `localhost` (`127.0.0.1`) and `network.publish_host` to
the pod IP.  Refer to: [Network Settings for
Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#modules-network)
for more information.

An example of Elasticsearch configuration that will work in Istio is shown below:

{{< text yaml >}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: es-cluster
  namespace: elastic
spec:
  serviceName: elasticsearch
  replicas: 3
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.2.0
        ...
        env:
          ...
          - name: network.bind_host
            value: 127.0.0.1
          - name: network.publish_host
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          ...
...
{{< /text >}}

1. `Service` Definition

Use a headless service for Elasticsearch by specifying the `clusterIP`
as `None` as shown in the following example:

{{< text yaml >}}
kind: Service
apiVersion: v1
metadata:
  name: elasticsearch
  namespace: elastic
  labels:
    app: elasticsearch
spec:
  selector:
    app: elasticsearch
  clusterIP: None
  ports:
    - port: 9200
      name: http-rest
    - port: 9300
      name: inter-node
{{< /text >}}

1. Using MTLS

If the REST API is accessed by accessing individual pods in the
StatefulSet, MTLS should be disabled or set to the `PERMISSIVE` mode.
