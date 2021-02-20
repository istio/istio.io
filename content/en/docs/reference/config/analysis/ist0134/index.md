---
title: ServiceEntryAddressesRequired
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when ServiceEntry with protocol TCP (or unset) protocol doesn't have addresses defined in the manifest.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0134] (ServiceEntry service-entry.default serviceentry.yaml:13) ServiceEntry addresses are required for this protocol.
{{< /text >}}

when your cluster have the following ServiceEntry with unset protocol and missing addresses:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: service-entry
  namespace: default
spec:
  hosts:
    - 'istio.io'
  exportTo:
    - "."
  ports:
    - number: 443
      name: https
  location: MESH_EXTERNAL
  resolution: DNS
{{< /text >}}

another example of this analyzer is when you have ServiceEntry with TCP protocol and missing addresses:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: service-entry
  namespace: default
spec:
  hosts:
    - 'istio.io'
  exportTo:
    - "."
  ports:
    - number: 443
      name: https
      protocol: TCP
  location: MESH_EXTERNAL
  resolution: DNS
{{< /text >}}

## How to resolve

Make sure to set `addresses` in ServiceEntry when using protocol TCP or unset protocol to avoid binding all traffic on the port define in the ServiceEntry.
