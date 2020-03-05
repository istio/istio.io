---
title: Configuration Validation Problems
description: Describes how to resolve configuration validation problems.
force_inline_toc: true
weight: 50
aliases:
    - /help/ops/setup/validation
    - /help/ops/troubleshooting/validation
    - /docs/ops/troubleshooting/validation
---

## Seemingly valid configuration is rejected

Manually verify your configuration is correct, cross-referencing
[Istio API reference](/docs/reference/config) when
necessary.

## Invalid configuration is accepted

Verify the `istiod-istio-system` `validationwebhookconfiguration` exists and
is correct. The `apiVersion`, `apiGroup`, and `resource` of the
invalid configuration should be listed in one of the two `webhooks`
entries.

{{< text bash yaml >}}
$ kubectl get validatingwebhookconfiguration istiod-istio-system -o yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  creationTimestamp: "2020-01-24T19:53:03Z"
  generation: 1
  labels:
    app: istiod
    istio: istiod
    release: istio
  name: istiod-istio-system
  ownerReferences:
  - apiVersion: rbac.authorization.k8s.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: ClusterRole
    name: istiod-istio-system
    uid: c3d24917-c2da-49ad-add3-c91c14608a45
  resourceVersion: "36649"
  selfLink: /apis/admissionregistration.k8s.io/v1/validatingwebhookconfigurations/istiod-istio-system
  uid: 043e39d9-377a-4a67-a7cf-7ae4cb3c562c
webhooks:
- admissionReviewVersions:
  - v1beta1
  clientConfig:
    # caBundle should be non-empty. This is periodically (re)patched
    # every second by the webhook service using the ca-cert
    # from the mounted service account secret.
    caBundle: LS0t...
    service:
      # service corresponds to the Kubernetes service that implements the
      # webhook, e.g. istio-galley.istio-system.svc:443
      name: istiod
      namespace: istio-system
      path: /validate
      port: 443
  failurePolicy: Fail
  matchPolicy: Exact
  name: validation.istio.io
  namespaceSelector: {}
  objectSelector: {}
  rules:
  - apiGroups:
    - config.istio.io
    - rbac.istio.io
    - security.istio.io
    - authentication.istio.io
    - networking.istio.io
    apiVersions:
    - '*'
    operations:
    - CREATE
    - UPDATE
    resources:
    - '*'
    scope: '*'
  sideEffects: None
  timeoutSeconds: 30
{{< /text >}}

If the `validatingwebhookconfiguration` doesn’t exist, verify the
`istio-validation` `configmap` exists. Istio uses
the data from this configmap to create and update the
`validatingwebhookconfiguration`.

{{< text bash yaml >}}
$ kubectl -n istio-system get configmap istio-validation -o jsonpath='{.data}'
map[config:apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  name: istiod-istio-system
  namespace: istio-system
  labels:
    app: istiod
    release: istio
    istio: istiod
webhooks:
  - name: validation.istio.io
    clientConfig:
      service:
        name: istiod
        namespace: istio-system
        path: "/validate"
        port: 443
      caBundle: ""
    rules:
      - operations:
        - CREATE
        - UPDATE
        apiGroups:
        - config.istio.io
        - rbac.istio.io
        - security.istio.io
        - authentication.istio.io
        - networking.istio.io
        apiVersions:
        - "*"
        resources:
        - "*"
    failurePolicy: Fail
    sideEffects: None]
      (... snip ...)
{{< /text >}}

If the webhook array in `istio-validation` is empty, verify
the `global.configValidation` installation options are
set.

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
