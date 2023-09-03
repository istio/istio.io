---
---
{{< boilerplate gateway-api-support >}}

{{< warning >}}
Note that this document uses the Gateway API to configure internal mesh (east-west) traffic,
i.e., not just ingress (north-south) traffic.
Configuring internal mesh traffic is an
[experimental feature](https://gateway-api.sigs.k8s.io/geps/overview/#status)
of the Gateway API, currently under development.
{{< /warning >}}
