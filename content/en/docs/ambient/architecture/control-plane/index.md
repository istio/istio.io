---
title: Ambient and the Istio control plane
description: Understand how ambient interacts with the Istio control plane.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

Like all Istio {{< gloss >}}data plane{{< /gloss >}} modes, Ambient uses the Istio {{< gloss >}}control plane{{< /gloss>}}. In ambient, the control plane communicates with the {{< gloss >}}ztunnel{{< /gloss >}} proxy on each Kubernetes node.

The figure shows an overview of the control plane related components and flows between ztunnel proxy and the `istiod` control plane.

{{< image width="100%"
link="ztunnel-architecture.svg"
caption="Ztunnel architecture"
>}}

The ztunnel proxy uses xDS APIs to communicate with the Istio control plane (`istiod`). This enables the fast, dynamic configuration updates required in modern distributed systems. The ztunnel proxy also obtains {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} certificates for the Service Accounts of all pods that are scheduled on its Kubernetes node using xDS. A single ztunnel proxy may implement L4 data plane functionality on behalf of any pod sharing it's node which requires efficiently obtaining relevant configuration and certificates. This multi-tenant architecture contrasts sharply with the sidecar model where each application pod has its own proxy.

It is also worth noting that in ambient mode, a simplified set of resources are used in the xDS APIs for ztunnel proxy configuration. This results in improved performance (having to transmit and process a much smaller set of information that is sent from istiod to the ztunnel proxies) and improved troubleshooting.
