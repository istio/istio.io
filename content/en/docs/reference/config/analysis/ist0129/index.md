---
title: NoServerCertificateVerificationPortLevel
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when `caCertificates` is not set in a destination rule, but is
needed for the traffic policy.

## Example

You will receive this message:

{{< text plain >}}
Error [IST0129] (DestinationRule db-tls.default) DestinationRule default/db-tls in namespace default has TLS mode set to SIMPLE but no caCertificates are set to validate server identity for host: mydbserver.prod.svc.cluster.local at port number:443
{{< /text >}}

when your cluster has the following destination rule:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: db-tls
spec:
  host: mydbserver.prod.svc.cluster.local
  trafficPolicy:
    portLevelSettings:
      - port:
          number: 443
        tls:
          mode: SIMPLE
          clientCertificate: /etc/certs/myclientcert.pem
          privateKey: /etc/certs/client_private_key.pem
          sni: my-nginx.mesh-external.svc.cluster.local
          # caCertificates not set
{{< /text >}}

In this example, the destination rule `db-tls` specifies
TLS, but does not set the CA certificate file.

## How to resolve

- Supply the filename of a CA certificate
- Change the traffic policy so that a certificate is not needed
