---
title: ExternalControlPlaneAddressIsNotAHostname
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when the address provided for the ingress gateway on the external control plane is an IP address and not a hostname.

## Example

You will receive this message:

{{< text plain >}}
Info [IST0164] (MutatingWebhookConfiguration istio-sidecar-injector-external-istiod testing.yml:28) The address (https://999.999.999.999:5100/inject/cluster/your-cluster-name/net/network1) that was provided for the webhook (rev.namespace.sidecar-injector.istio.io) to reach the ingress gateway on the external control plane cluster is an IP address. This is not recommended for a production environment.
{{< /text >}}

when your cluster has the following `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration` (shortened for clarity):

{{< text yaml >}}
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: istio-validator-external-istiod
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com:15017/validate
  name: rev.validation.istio.io

---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: istiod-default-validator
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com:15017/validate
  failurePolicy: Ignore
  name: validation.istio.io

---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector-external-istiod
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://999.999.999.999:5100/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: rev.namespace.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: rev.object.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: namespace.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: object.sidecar-injector.istio.io
{{< /text >}}

## How to resolve

Using an IP address instead of a hostname for your ingress gateway running in the external control plane is not recommended in a production environment.

If you are running in a production environment, you can fix this info message by changing the address to a valid hostname that resolves to the IP address of your ingress gateway.

Instructions for exposing the ingress gateway service using a public hostname with TLS can be found [here](/docs/setup/install/external-controlplane/#set-up-a-gateway-in-the-external-cluster).
