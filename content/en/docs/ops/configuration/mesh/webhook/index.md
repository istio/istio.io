---
title: Dynamic Admission Webhooks Overview
description: Provides a general overview of Istio's use of Kubernetes webhooks and the related issues that can arise.
weight: 10
aliases:
  - /help/ops/setup/webhook
  - /docs/ops/setup/webhook
owner: istio/wg-user-experience-maintainers
test: no
---

From [Kubernetes mutating and validating webhook mechanisms](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/):

{{< tip >}}
Admission webhooks are HTTP callbacks that receive admission requests
and do something with them. You can define two types of admission
webhooks, validating admission webhook and mutating admission
webhook. With validating admission webhooks, you may reject requests
to enforce custom admission policies. With mutating admission
webhooks, you may change requests to enforce custom defaults.
{{< /tip >}}

Istio uses `ValidatingAdmissionWebhooks` for validating Istio
configuration and `MutatingAdmissionWebhooks` for automatically
injecting the sidecar proxy into user pods.

The webhook setup guides assuming general familiarity with Kubernetes
Dynamic Admission Webhooks. Consult the Kubernetes API references for
detailed documentation of the [Mutating Webhook Configuration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#mutatingwebhookconfiguration-v1-admissionregistration-k8s-io) and [Validating Webhook Configuration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#validatingwebhookconfiguration-v1-admissionregistration-k8s-io).

## Verify dynamic admission webhook prerequisites

See the [platform setup instructions](/docs/setup/platform-setup/)
for Kubernetes provider specific setup instructions. Webhooks will not
function properly if the cluster is misconfigured. You can follow
these steps once the cluster has been configured and dynamic
webhooks and dependent features are not functioning properly.

1. Verify you’re using a [supported version](/docs/releases/supported-releases#support-status-of-istio-releases) ({{< supported_kubernetes_versions >}}) of
   [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and of the Kubernetes server:

    {{< text bash >}}
    $ kubectl version --short
    Client Version: v1.19.0
    Server Version: v1.19.1
    {{< /text >}}

1. `admissionregistration.k8s.io/v1` should be enabled

    {{< text bash >}}
    $ kubectl api-versions | grep admissionregistration.k8s.io/v1
    admissionregistration.k8s.io/v1
    {{< /text >}}

1. Verify `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` plugins are
   listed in the `kube-apiserver --enable-admission-plugins`. Access
   to this flag is [provider specific](/docs/setup/platform-setup/).

1. Verify the Kubernetes api-server has network connectivity to the
   webhook pod. e.g. incorrect `http_proxy` settings can interfere
   api-server operation (see related issues
   [here](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)
   and [here](https://github.com/kubernetes/kubeadm/issues/666) for more information).
