---
title: Provision a certificate and key for an application without sidecars
description: A mechanism to acquire and share an application certificate and key through mounted files.
publishdate: 2020-03-25
attribution: Lei Tang (Google)
keywords: [certificate,sidecar]
target_release: 1.5
---

{{< boilerplate experimental-feature-warning >}}

Istio sidecars obtain their certificates using
the secret discovery service.
A service in the service mesh may not need (or want) an Envoy sidecar
to handle its traffic. In this case, the service will need
to obtain a certificate itself if it wants to connect to other TLS or mutual TLS secured services.

For a service with no need of a sidecar to manage its traffic, a sidecar can nevertheless still be
deployed only to provision the private key and certificates through
the CSR flow from the CA and then share the certificate with the service
through a mounted file in `tmpfs`.
We have used Prometheus as our example application for provisioning
a certificate using this mechanism.

In the example application (i.e., Prometheus), a sidecar is added to the
Prometheus deployment by setting the flag `.Values.prometheus.provisionPrometheusCert`
to `true` (this flag is set to true by default in an Istio installation).
This deployed sidecar will then request and share a
certificate with Prometheus.

The key and certificate provisioned for the example application
are mounted in the directory `/etc/istio-certs/`.
We can list the key and certificate provisioned for the application by
running the following command:

{{< text bash >}}
$ kubectl exec -it `kubectl get pod -l app=prometheus -n istio-system -o jsonpath='{.items[0].metadata.name}'` -c prometheus -n istio-system -- ls -la /etc/istio-certs/
{{< /text >}}

The output from the above command should include non-empty key and certificate files, similar to the following:

{{< text plain >}}
-rwxr-xr-x    1 root     root          2209 Feb 25 13:06 cert-chain.pem
-rwxr-xr-x    1 root     root          1679 Feb 25 13:06 key.pem
-rwxr-xr-x    1 root     root          1054 Feb 25 13:06 root-cert.pem
{{< /text >}}

If you want to use this mechanism to provision a certificate
for your own application, take a look at our
[Prometheus example application]({{< github_blob >}}/manifests/istio-telemetry/prometheus/templates/deployment.yaml) and simply follow the same pattern.
