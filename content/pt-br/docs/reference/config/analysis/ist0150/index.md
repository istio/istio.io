---
title: ExternalNameServiceTypeInvalidPortName
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs for services of type ExternalName when the port doesn't follow Istio service port naming convention, the port is unnamed or the port is named tcp.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0150] (Service nginx.default) Port name for ExternalName service is invalid. Proxy may prevent tcp named ports and unmatched traffic for ports serving TCP protocol from being forwarded correctly.
{{< /text >}}

when your cluster has the following service:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  externalName: nginx.example.com
  ports:
  - name: tcp
    port: 443
    protocol: TCP
    targetPort: 443
  type: ExternalName
{{< /text >}}

In this example, the port name `tcp` follows the syntax: `name: <protocol>`. However, for ExternalName services, there is no service IP defined, so the SNI field is needed for routing.

## How to resolve

- If you have an ExternalName service type, and the protocol is TCP, rename the port to `<protocol>[-<suffix>]` or `<protocol>` where protocol is `https` or `tls`. To learn more, review
docs on [explicit protocol selection](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection).
