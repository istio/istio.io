---
title: Dynamic Admission Webhooks Overview
description: Provides a general overview of Istio's use of Kubernetes webhooks and the related issues that can arise.
weight: 10
---

From [Kubernetes mutating and validating webhook mechanisms](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/):

> Admission webhooks are HTTP callbacks that receive admission requests
and do something with them. You can define two types of admission
webhooks, validating admission webhook and mutating admission
webhook. With validating admission webhooks, you may reject requests
to enforce custom admission policies. With mutating admission
webhooks, you may change requests to enforce custom defaults.

Istio uses `ValidatingAdmissionWebhooks` for validating Istio
configuration and `MutatingAdmissionWebhooks` for automatically
injecting the sidecar proxy into user pods.

The webhook setup guides assuming general familiarity with Kubernetes
Dynamic Admission Webhooks. Consult the [Kubernetes API references](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/) for
detailed documentation of the mutating and validating webhook configuration.

## Verify dynamic admission webhook prerequisites

See the [quick start prerequisites](/docs/setup/kubernetes/quick-start/#prerequisites)
for Kubernetes provider specific setup instructions. Webhooks will not
function properly if the cluster is misconfigured. You can follow
these steps once the cluster has been configured and dynamic
webhooks and dependent features are not functioning properly.

1. Verify you’re using the
   [latest](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
   version of `kubectl` (>= 1.10) and that the Kubernetes server version
   is >= 1.9.

    {{< text bash >}}
    $ kubectl version --short
    Client Version: v1.10.2
    Server Version: v1.10.4-gke.0
    {{< /text >}}

1. `admissionregistration.kubernetes.io/v1beta1` should be enabled

    {{< text bash >}}
    $ kubectl api-versions |grep admissionregistration.Kubernetes.io/v1beta1
    admissionregistration.Kubernetes.io/v1beta1
    {{< /text >}}

1. Verify `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` plugins are
   listed in the `kube-apiserver --enable-admission-plugins`. Access
   to this flag is [provider specific](/docs/setup/kubernetes/quick-start/#prerequisites).

1. Verify the Kubernetes api-server has network connectivity to the
   webhook pod. e.g. incorrect `http_proxy` settings can interfere
   api-server operation (see related issues
   [here](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)
   and [here](https://github.com/kubernetes/kubeadm/issues/666) for more information).
