---
title: Configuration Validation Problems
description: Describes how to resolve configuration validation problems.
force_inline_toc: true
weight: 50
aliases:
    - /help/ops/setup/validation
    - /help/ops/troubleshooting/validation
    - /docs/ops/troubleshooting/validation
owner: istio/wg-user-experience-maintainers
test: no
---

## Seemingly valid configuration is rejected

Use [istioctl validate -f](/docs/reference/commands/istioctl/#istioctl-validate) and [istioctl analyze](/docs/reference/commands/istioctl/#istioctl-analyze) for more insight into why the configuration is rejected.  Use an _istioctl_ CLI with a similar version to the control plane version.

The most commonly reported problems with configuration are YAML indentation and array notation (`-`) mistakes.

Manually verify your configuration is correct, cross-referencing
[Istio API reference](/docs/reference/config) when
necessary.

## Invalid configuration is accepted

Verify that a `validatingwebhookconfiguration` named `istio-validator-` followed by
`<revision>-`, if not the default revision, followed by the Istio system namespace
(e.g., `istio-validator-myrev-istio-system`) exists and is correct.
The `apiVersion`, `apiGroup`, and `resource` of the
invalid configuration should be listed in the `webhooks` section of the `validatingwebhookconfiguration`.

{{< text bash yaml >}}
$ kubectl get validatingwebhookconfiguration istio-validator-istio-system -o yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  labels:
    app: istiod
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio: istiod
    istio.io/rev: default
    operator.istio.io/component: Pilot
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: unknown
    release: istio
  name: istio-validator-istio-system
  resourceVersion: "615569"
  uid: 112fed62-93e7-41c9-8cb1-b2665f392dd7
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    # caBundle should be non-empty. This is periodically (re)patched
    # every second by the webhook service using the ca-cert
    # from the mounted service account secret.
    caBundle: LS0t...
    # service corresponds to the Kubernetes service that implements the webhook
    service:
      name: istiod
      namespace: istio-system
      path: /validate
      port: 443
  failurePolicy: Fail
  matchPolicy: Equivalent
  name: rev.validation.istio.io
  namespaceSelector: {}
  objectSelector:
    matchExpressions:
    - key: istio.io/rev
      operator: In
      values:
      - default
  rules:
  - apiGroups:
    - security.istio.io
    - networking.istio.io
    - telemetry.istio.io
    - extensions.istio.io
    apiVersions:
    - '*'
    operations:
    - CREATE
    - UPDATE
    resources:
    - '*'
    scope: '*'
  sideEffects: None
  timeoutSeconds: 10
{{< /text >}}

If the `istio-validator-` webhook does not exist, verify
the `global.configValidation` installation option is
set to `true`.

The validation configuration is fail-close. If
configuration exists and is scoped properly, the webhook will be
invoked. A missing `caBundle`, bad certificate, or network connectivity
problem will produce an error message when the resource is
created/updated. If you don’t see any error message and the webhook
wasn’t invoked and the webhook configuration is valid, your cluster is
misconfigured.

## Creating configuration fails with x509 certificate errors

`x509: certificate signed by unknown authority` related errors are
typically caused by an empty `caBundle` in the webhook
configuration. Verify that it is not empty (see [verify webhook
configuration](#invalid-configuration-is-accepted)). Istio consciously reconciles webhook configuration
used the `istio-validation` `configmap` and root certificate.

1. Verify the `istiod` pod(s) are running:

    {{< text bash >}}
    $  kubectl -n istio-system get pod -lapp=istiod
    NAME                            READY     STATUS    RESTARTS   AGE
    istiod-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

1. Check the pod logs for errors. Failing to patch the
       `caBundle` should print an error.

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

1. If the patching failed, verify the RBAC configuration for Istiod:

    {{< text bash yaml >}}
    $ kubectl get clusterrole istiod-istio-system -o yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
      name: istiod-istio-system
    rules:
    - apiGroups:
      - admissionregistration.k8s.io
      resources:
      - validatingwebhookconfigurations
      verbs:
      - '*'
    {{< /text >}}

    Istio needs `validatingwebhookconfigurations` write access to
    create and update the `validatingwebhookconfiguration`.

## Creating configuration fails with `no such hosts` or `no endpoints available` errors

Validation is fail-close. If the `istiod` pod is not ready,
configuration cannot be created and updated.  In such cases you’ll see
an error about `no endpoints available`.

Verify the `istiod` pod(s) are running and endpoints are ready.

{{< text bash >}}
$  kubectl -n istio-system get pod -lapp=istiod
NAME                            READY     STATUS    RESTARTS   AGE
istiod-5dbbbdb746-d676g   1/1       Running   0          2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istiod
NAME           ENDPOINTS                          AGE
istiod         10.48.6.108:15014,10.48.6.108:443   3d
{{< /text >}}

If the pods or endpoints aren't ready, check the pod logs and
status for any indication about why the webhook pod is failing to start
and serve traffic.

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done
{{< /text >}}

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}
