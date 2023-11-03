---
title: ServiceEntryAddressesRequired
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when a `ServiceEntry` with the `protocol` field not set, or set to `TCP`, doesn't have `addresses` defined.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0134] (ServiceEntry service-entry.default serviceentry.yaml:13) ServiceEntry addresses are required for this protocol.
{{< /text >}}

When your cluster has the following `ServiceEntry` with unset `protocol` and missing `addresses`:

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

Another example of this analyzer is when you have a `ServiceEntry` with `protocol: TCP` and missing `addresses`:

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

Make sure to set `addresses` in your `ServiceEntry` when `protocol` is not set, or set to TCP. If `addresses` is not set, all traffic on the port defined in the `ServiceEntry` is matched, regardless of the host.
