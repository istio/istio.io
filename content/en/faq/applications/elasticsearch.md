---
title: Elasticsearch Configuration
description: Elasticsearch configuration required for use with Istio
weight: 50
keywords: [elasticsearch]
---

1. Elasticsearch Configuration

There are two Elasticsearch configuration parameters that need to be
set appropriately for running Elasticsearch with Istio:
`network.bind_host` and `network.publish_host`.  By default, these
parameters are set to the `network.host` parameter. If this parameter
is set to `0.0.0.0`, Elasticsearch will most likely pick up the pod IP
as the publishing address and therefore no additional configuration is
needed.

In order to run Elasticsearch with Istio one can explicitly set the
`network.bind_host` to `0.0.0.0` or `localhost` (`127.0.0.1`) and
`network.publish_host` to the pod IP to avoid any configuration issue.
Refer to: [Network Settings for
Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#modules-network)
for more information.

With some configurations, ES can be deployed and work correctly
without a service mesh while failing to work in a service mesh.  A
commonly seen such configuration sets the `network.host` parameter to
the pod IP. In cases where Elasticsearch dose not pick the correct
addresses by default, for example when the host has multiple IP
addresses, the `network.publish_host` and `network.bind_host`
parameter should be set to the desired IP addresses.

{{< text plain >}}
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

{{< text plain >}}
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

1. `Statefulset` Definition

Make sure ports are specified in the `Statefulset` definition as shown in the snippet below:

{{< text plain >}}
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
        ports:
        - containerPort: 9200
        - containerPort: 9300
        ...
...
{{< /text >}}