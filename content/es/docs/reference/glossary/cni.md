---
title: CNI
test: n/a
---

The [Container Network Interface (CNI)](https://www.cni.dev/) is the standard used by Kubernetes for configuring cluster networking. It is implemented using *plugins*, of which there are two types:

* *interface* plugins, which create a network interface, and are provided by the cluster operator
* *chained* plugins, which can configure the created interface, and can be provided by software installed on the cluster

Istio works with all CNI implementations that follow the CNI standard, in both sidecar and ambient mode.

In order to configure mesh traffic redirection, Istio includes a [CNI node agent](/es/docs/setup/additional-setup/cni/). This agent installs a chained CNI plugin, which runs after all configured CNI interface plugins.

The CNI node agent is optional for {{< gloss >}}sidecar{{< /gloss >}} mode and required for {{< gloss >}}ambient{{< /gloss >}} mode.
