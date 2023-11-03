---
title: InvalidExternalControlPlaneConfig
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when the address provided for the ingress gateway on the external control plane is not valid. The address could be invalid for several reasons including: the hostname address is malformed, the hostname cannot be resolved to an IP address via a DNS lookup, or the hostname resolves to zero IP addresses.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0163] (MutatingWebhookConfiguration istio-sidecar-injector-external-istiod testing.yml:28) The hostname () that was provided for the webhook (rev.namespace.sidecar-injector.istio.io) to reach the ingress gateway on the external control plane cluster is blank. Traffic may not flow properly.
Warning [IST0163] (ValidatingWebhookConfiguration istio-validator-external-istiod testing.yml:1) The hostname () that was provided for the webhook (rev.validation.istio.io) to reach the ingress gateway on the external control plane cluster is blank. Traffic may not flow properly.
{{< /text >}}

when your cluster has the following `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration` (shortened for clarity) that are missing webhook URLs:

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
    url:
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
    url:
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

You will receive this message:

{{< text plain >}}
Warning [IST0163] (ValidatingWebhookConfiguration istio-validator-external-istiod testing.yml:1) The hostname (https://thisisnotarealdomainname.com:15017/validate) that was provided for the webhook (rev.validation.istio.io) to reach the ingress gateway on the external control plane cluster cannot be resolved via a DNS lookup. Traffic may not flow properly.
{{< /text >}}

when your cluster has the following `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration` (shortened for clarity) that are using a hostname that cannot be resolved during a DNS lookup:

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
    url: https://thisisnotarealdomainname.com:15017/validate
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
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
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

There are several ways to resolve these invalid configurations, depending on why the configuration is invalid.

If your webhook configurations have no URLs defined, adding valid URLs that use a hostname will resolve this warning message. Instructions on how to do that can be found [here](/docs/setup/install/external-controlplane/#set-up-the-remote-config-cluster).

If your hostname cannot be resolved to an IP address via a DNS lookup, you can try running `dig <your-hostname>` on your local machine to see if a DNS resolution occurs. If your local machine can resolve the hostname via a DNS lookup, your cluster may not be able to. Any security rules blocking DNS traffic could result in a failure to resolve lookups. New DNS records may take up to 72 hours to propagate across the web depending on your DNS provider and specific configuration.

If your hostname resolves to zero IP addresses, check that the webhook URLs are using the correct hostname and that your DNS provider correctly has at least one IP address for your hostname to resolve to.
