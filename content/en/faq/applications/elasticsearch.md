---
title: Can I run Elasticsearch inside an Istio mesh?
description: Elasticsearch configuration required for use with Istio
weight: 50
keywords: [elasticsearch]
---

There are two Elasticsearch configuration parameters that need to be
set appropriately to run Elasticsearch with Istio:
`network.bind_host` and `network.publish_host`. By default, these
parameters are set to the `network.host` parameter. If `network.host`
is set to `0.0.0.0`, Elasticsearch will most likely pick up the pod IP
as the publishing address and no further configuration will be
needed.

If the default configuration does not work, you can set the
`network.bind_host` to `0.0.0.0` or `localhost` (`127.0.0.1`) and
`network.publish_host` to the pod IP. For example:

{{< text yaml >}}
...
containers:
- name: elasticsearch
  image: docker.elastic.co/elasticsearch/elasticsearch:7.2.0
  env:
    - name: network.bind_host
      value: 127.0.0.1
    - name: network.publish_host
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
   ...
{{< /text >}}

Refer to [Network Settings for Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#modules-network)
for more information.
