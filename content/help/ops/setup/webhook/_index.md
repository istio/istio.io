---
title: Dynamic Admission Webhooks
description: Describes Istio's use of Kubernetes webhooks and the related issues that can arise.
weight: 10
---

This page assumes you're familiar with the [Kubernetes mutating and
validating webhook
mechanisms](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/). Consult
the Kubernetes API references for detailed documentation of the
[mutating](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#mutatingwebhookconfiguration-v1beta1-admissionregistration-kubernetes-io)
and
[validating](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#validatingwebhookconfiguration-v1beta1-admissionregistration-kubernetes-io)
webhook configuration.

You may need to modify and/or verify the following specific fields in
the webhook configuration:

**`namespaceSelector`** - decides whether to run the webhook on an
object based on whether the namespace for that object matches the
selector. If the object is a cluster scoped resource, it never skips
the webhook.

* Configuration validation applies to all namespaces (by default).

* Automatic injection is scoped to be opt-in (namespaces labeled with
  istio-injection=enabled) or opt-out (namespaces *not* labeled with
  istio-injection=disabled).

**`failurePolicy`** - defines how unrecognized errors from the admission
endpoint are handled - allowed values are Ignore or Fail.

* Both automatic injection and configuration validation use fail-close
  (`failurePolicy=Fail`). Creation of resources defined by the rules
  (see below) will fail if the webhook pods are not running, not
  reachable, or misconfigured.

**rules** - describes what operations on what resources / subresources
the webhook cares about. The webhook cares about an operation if it
matches any rule.

* Configuration validation rules match creation and editing of Istio
  CustomResourceDefinitions (CRD).

* Automatic injection rules match creation of pods.

**`clientConfig`** - defines how the Kubernetes api-server communicates
with the webhook. This includes the Kubernetes service name of the
webhook as well as the CA bundle for simple TLS (via `caBundle`). The
`caBundle` is automatically patched by the respective webhook pod. The
webhook configurations in the release `istio.yaml` include empty
`caBundle`.

## Prerequisites

See the [quick start prerequisites](https://istio.io/docs/setup/kubernetes/quick-start/#prerequisites)
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
   to this flag is provider specific (see
   [here](https://istio.io/docs/setup/kubernetes/quick-start/#prerequisites))

1. Verify the Kubernetes api-server has network connectivity to the
   webhook pod. e.g. incorrect `http_proxy` settings can interfere
   api-server operation (see
   [here](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)
   and [here](https://github.com/kubernetes/kubeadm/issues/666)).
