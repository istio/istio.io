---
title: Can I run Redis inside an Istio mesh?
description: How to run Redis with Istio.
weight: 50
keywords: [redis]
---

Similar to other services deployed in an Istio mesh, Redis instances
need to listen on `localhost` (`127.0.0.1`). However, each Redis slave
instance should announce an address that can be used by master to
reach it. Obviously, This address cannot be `localhost` (`127.0.0.1`).

The Redis configuration parameter `replica-announce-ip` can be used to
announce the correct address.  For example, one can set
`replica-announce-ip` to the IP address of each Redis slave
instance. In order to do that, first pass the pod IP address through
an environment variable in the `env` subsection of the slave
`StatefulSet` definition:

{{< text yaml >}}
    - name: "POD_IP"
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
{{< /text >}}

and add the following under the `command` subsection:

{{< text yaml >}}
echo "" >> /opt/bitnami/redis/etc/replica.conf
echo "replica-announce-ip $POD_IP" >> /opt/bitna
{{< /text >}}
