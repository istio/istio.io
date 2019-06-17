---
title: Sidecars
description: Learn about using a sidecar to configure the scope of the Envoy proxies to enable certain features, like namespace isolation.
weight: 5
keywords: [traffic-management, envoy, namespace-isolation, performance]
---

By default, Istio configures every Envoy proxy to accept traffic on all the
ports of its associated workload, and to reach every workload in the mesh when
forwarding traffic. You can use a sidecar configuration to do the following:

-  Fine-tune the set of ports and protocols that an Envoy proxy accepts.

-  Limit the set of services that the Envoy proxy can reach.

Limiting sidecar reachability reduces memory usage, which can become a problem
for large applications in which every sidecar is configured to reach every
other service in the mesh.

A [Sidecar](/docs/reference/config/networking/v1alpha3/sidecar/) resource can be used to configure one or more sidecar proxies
selected using workload labels, or to configure all sidecars in a particular
namespace.

## Enable namespace isolation

For example, the following `Sidecar` configures all services in the `bookinfo`
namespace to only reach services running in the same namespace thanks to the
`./*` value of the `hosts:` field:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
  namespace: bookinfo
spec:
  egress:
  - hosts:
    - "./*"
{{< /text >}}

Sidecars have many uses. Refer to the [sidecar reference](/docs/reference/config/networking/v1alpha3/sidecar/)
for details.
