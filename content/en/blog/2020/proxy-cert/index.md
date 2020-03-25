---
title: Provision a certificate and key to your application through files [Experimental]
description: Provision a certificate and key to your application through files.
publishdate: 2020-02-20
attribution: Lei Tang (Google)
keywords: [certificate,sidecar]
target_release: 1.5
---

{{< boilerplate experimental-feature-warning >}}

Istio sidecars can obtain certificates through
the secret discovery service.
A service in the service mesh may not need an Envoy sidecar
to handle its TLS/mTLS connections. Instead, the service wants
to obtain a certificate and handle the TLS/mTLS connections itself.
For a service not needing a sidecar to get a certificate,
it may deploy a sidecar only to provision the private key and certificates through
the CSR flow from the CA and share the certificate with the service
through a mounted file in `tmpfs`.
We use Prometheus as an example application to show provisioning
a certificate through such mechanism.

In the example application (i.e., Prometheus), a sidecar is added to the
Prometheus deployment when the flag `.Values.prometheus.provisionPrometheusCert`
is set to `true` (this flag is set as true by default in an Istio installation).
The sidecar requests for a certificate and shares the
certificate with Prometheus.

The key and certificate provisioned for the example application
are mounted to the directory `/etc/istio-certs/`.
To list the key and certificate provisioned for the example application,
run the following command:

{{< text bash >}}
$ kubectl exec -it `kubectl get pod -l app=prometheus -n istio-system -o jsonpath='{.items[0].metadata.name}'` -c prometheus -n istio-system -- ls -la /etc/istio-certs/
{{< /text >}}

The output from the above command should include non-empty key and certificate files. The following
is an example output:

{{< text plain >}}
-rwxr-xr-x    1 root     root          2209 Feb 25 13:06 cert-chain.pem
-rwxr-xr-x    1 root     root          1679 Feb 25 13:06 key.pem
-rwxr-xr-x    1 root     root          1054 Feb 25 13:06 root-cert.pem
{{< /text >}}

If you want to use the mechanism in this article to provision a certificate
to an application, you can imitate the example application and add a sidecar
like [the one in the example application]({{< github_blob >}}/manifests/istio-telemetry/prometheus/templates/deployment.yaml)
to your application.
