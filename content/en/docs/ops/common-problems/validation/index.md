---
title: Galley Configuration Problems
description: Describes how to resolve Galley configuration problems.
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

Verify the `istio-galley` `validationwebhookconfiguration` exists and
is correct. The `apiVersion`, `apiGroup`, and `resource` of the
invalid configuration should be listed in one of the two `webhooks`
entries.

{{< text bash yaml >}}
$ kubectl get validatingwebhookconfiguration istio-galley -o yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  labels:
    app: istio-galley
  name: istio-galley
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: Deployment
    name: istio-galley
    uid: 5c64585d-91c6-11e8-a98a-42010a8001a8
webhooks:
- clientConfig:
    # caBundle should be non-empty. This is periodically (re)patched
    # every second by the webhook service using the ca-cert
    # from the mounted service account secret.
    caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1VENDQWMyZ0F3SUJBZ0lRVzVYNWpJcnJCemJmZFdLaWVoaVVSakFOQmdrcWhraUc5dzBCQVFzRkFEQWMKTVJvd0dBWURWUVFLRXhGck9ITXVZMngxYzNSbGNpNXNiMk5oYkRBZUZ3MHhPREEzTWpjeE56VTJNakJhRncweApPVEEzTWpjeE56VTJNakJhTUJ3eEdqQVlCZ05WQkFvVEVXczRjeTVqYkhWemRHVnlMbXh2WTJGc01JSUJJakFOCkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXdVMi9SdWlyeTNnUzdPd2xJRCtaaGZiOEpOWnMKK05OL0dRWUsxbVozb3duaEw4dnJHdDBhenpjNXFuOXo2ZEw5Z1pPVFJXeFVCYXVJMUpOa3d0dSt2NmRjRzlkWgp0Q2JaQWloc1BLQWQ4MVRaa3RwYkNnOFdrcTRyNTh3QldRemNxMldsaFlPWHNlWGtRejdCbStOSUoyT0NRbmJwCjZYMmJ4Slc2OGdaZkg2UHlNR0libXJxaDgvZ2hISjFha3ptNGgzc0VGU1dTQ1Y2anZTZHVJL29NM2pBem5uZlUKU3JKY3VpQnBKZmJSMm1nQm4xVmFzNUJNdFpaaTBubDYxUzhyZ1ZiaHp4bWhpeFhlWU0zQzNHT3FlRUthY0N3WQo0TVczdEJFZ3NoN2ovZGM5cEt1ZG1wdFBFdit2Y2JnWjdreEhhazlOdFV2YmRGempJeTMxUS9Qd1NRSURBUUFCCm95TXdJVEFPQmdOVkhROEJBZjhFQkFNQ0FnUXdEd1lEVlIwVEFRSC9CQVV3QXdFQi96QU5CZ2txaGtpRzl3MEIKQVFzRkFBT0NBUUVBTnRLSnVkQ3NtbTFzU3dlS2xKTzBIY1ZMQUFhbFk4ZERUYWVLNksyakIwRnl0MkM3ZUtGSAoya3JaOWlkbWp5Yk8xS0djMVlWQndNeWlUMGhjYWFlaTdad2g0aERRWjVRN0k3ZFFuTVMzc2taR3ByaW5idU1aCmg3Tm1WUkVnV1ZIcm9OcGZEN3pBNEVqWk9FZzkwR0J6YXUzdHNmanI4RDQ1VVRJZUw3M3hwaUxmMXhRTk10RWEKd0NSelplQ3lmSUhra2ZrTCtISVVGK0lWV1g2VWp2WTRpRDdRR0JCenpHZTluNS9KM1g5OU1Gb1F3bExjNHMrTQpnLzNQdnZCYjBwaTU5MWxveXluU3lkWDVqUG5ibDhkNEFJaGZ6OU8rUTE5UGVULy9ydXFRNENOancrZmVIbTBSCjJzYmowZDd0SjkyTzgwT2NMVDlpb05NQlFLQlk3cGlOUkE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    service:
      # service corresponds to the Kubernetes service that implements the
      # webhook, e.g. istio-galley.istio-system.svc:443
      name: istio-galley
      namespace: istio-system
      path: /admitpilot
  failurePolicy: Fail
  name: pilot.validation.istio.io
  namespaceSelector: {}
  rules:
  - apiGroups:
    - config.istio.io
    apiVersions:
    - v1alpha2
    operations:
    - CREATE
    - UPDATE
    resources:
    - httpapispecs
    - httpapispecbindings
    - quotaspecs
    - quotaspecbindings
  - apiGroups:
    - rbac.istio.io
    apiVersions:
    - '*'
    operations:
    - CREATE
    - UPDATE
    resources:
    - '*'
  - apiGroups:
    - authentication.istio.io
    apiVersions:
    - '*'
    operations:
    - CREATE
    - UPDATE
    resources:
    - '*'
  - apiGroups:
    - networking.istio.io
    apiVersions:
    - '*'
    operations:
    - CREATE
    - UPDATE
    resources:
    - destinationrules
    - envoyfilters
    - gateways
    - virtualservices
- clientConfig:
    # caBundle should be non-empty. This is periodically (re)patched
    # every second by the webhook service using the ca-cert
    # from the mounted service account secret.
    caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1VENDQWMyZ0F3SUJBZ0lRVzVYNWpJcnJCemJmZFdLaWVoaVVSakFOQmdrcWhraUc5dzBCQVFzRkFEQWMKTVJvd0dBWURWUVFLRXhGck9ITXVZMngxYzNSbGNpNXNiMk5oYkRBZUZ3MHhPREEzTWpjeE56VTJNakJhRncweApPVEEzTWpjeE56VTJNakJhTUJ3eEdqQVlCZ05WQkFvVEVXczRjeTVqYkhWemRHVnlMbXh2WTJGc01JSUJJakFOCkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXdVMi9SdWlyeTNnUzdPd2xJRCtaaGZiOEpOWnMKK05OL0dRWUsxbVozb3duaEw4dnJHdDBhenpjNXFuOXo2ZEw5Z1pPVFJXeFVCYXVJMUpOa3d0dSt2NmRjRzlkWgp0Q2JaQWloc1BLQWQ4MVRaa3RwYkNnOFdrcTRyNTh3QldRemNxMldsaFlPWHNlWGtRejdCbStOSUoyT0NRbmJwCjZYMmJ4Slc2OGdaZkg2UHlNR0libXJxaDgvZ2hISjFha3ptNGgzc0VGU1dTQ1Y2anZTZHVJL29NM2pBem5uZlUKU3JKY3VpQnBKZmJSMm1nQm4xVmFzNUJNdFpaaTBubDYxUzhyZ1ZiaHp4bWhpeFhlWU0zQzNHT3FlRUthY0N3WQo0TVczdEJFZ3NoN2ovZGM5cEt1ZG1wdFBFdit2Y2JnWjdreEhhazlOdFV2YmRGempJeTMxUS9Qd1NRSURBUUFCCm95TXdJVEFPQmdOVkhROEJBZjhFQkFNQ0FnUXdEd1lEVlIwVEFRSC9CQVV3QXdFQi96QU5CZ2txaGtpRzl3MEIKQVFzRkFBT0NBUUVBTnRLSnVkQ3NtbTFzU3dlS2xKTzBIY1ZMQUFhbFk4ZERUYWVLNksyakIwRnl0MkM3ZUtGSAoya3JaOWlkbWp5Yk8xS0djMVlWQndNeWlUMGhjYWFlaTdad2g0aERRWjVRN0k3ZFFuTVMzc2taR3ByaW5idU1aCmg3Tm1WUkVnV1ZIcm9OcGZEN3pBNEVqWk9FZzkwR0J6YXUzdHNmanI4RDQ1VVRJZUw3M3hwaUxmMXhRTk10RWEKd0NSelplQ3lmSUhra2ZrTCtISVVGK0lWV1g2VWp2WTRpRDdRR0JCenpHZTluNS9KM1g5OU1Gb1F3bExjNHMrTQpnLzNQdnZCYjBwaTU5MWxveXluU3lkWDVqUG5ibDhkNEFJaGZ6OU8rUTE5UGVULy9ydXFRNENOancrZmVIbTBSCjJzYmowZDd0SjkyTzgwT2NMVDlpb05NQlFLQlk3cGlOUkE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    service:
      # service corresponds to the Kubernetes service that implements the
      # webhook, e.g. istio-galley.istio-system.svc:443
      name: istio-galley
      namespace: istio-system
      path: /admitmixer
  failurePolicy: Fail
  name: mixer.validation.istio.io
  namespaceSelector: {}
  rules:
  - apiGroups:
    - config.istio.io
    apiVersions:
    - v1alpha2
    operations:
    - CREATE
    - UPDATE
    resources:
    - rules
    - attributemanifests
    - circonuses
    - deniers
    - fluentds
    - kubernetesenvs
    - listcheckers
    - memquotas
    - noops
    - opas
    - prometheuses
    - rbacs
    - servicecontrols
    - solarwindses
    - stackdrivers
    - statsds
    - stdios
    - apikeys
    - authorizations
    - checknothings
    - listentries
    - logentries
    - metrics
    - quotas
    - reportnothings
    - servicecontrolreports
    - tracespans
{{< /text >}}

If the `validatingwebhookconfiguration` doesn’t exist, verify the
`istio-galley-configuration` `configmap` exists. `istio-galley` uses
the data from this configmap to create and update the
`validatingwebhookconfiguration`.

{{< text bash yaml >}}
$ kubectl -n istio-system get configmap istio-galley-configuration -o jsonpath='{.data}'
map[validatingwebhookconfiguration.yaml:apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  name: istio-galley
  namespace: istio-system
  labels:
    app: istio-galley
    chart: galley-1.0.0
    release: istio
    heritage: Tiller
webhooks:
  - name: pilot.validation.istio.io
    clientConfig:
      service:
        name: istio-galley
        namespace: istio-system
        path: "/admitpilot"
      caBundle: ""
    rules:
      - operations:
      (... snip ...)
{{< /text >}}

If the webhook array in `istio-galley-configuration` is empty, verify
the `galley.enabled` and `global.configValidation` installation options are
set.

The `istio-galley` validation configuration is fail-close. If
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
configuration](#invalid-configuration-is-accepted)). The
`istio-galley` deployment consciously reconciles webhook configuration
used the `istio-galley-configuration` `configmap` and root certificate
mounted from `istio.istio-galley-service-account` secret in the
`istio-system` namespace.

1. Verify the `istio-galley` pod(s) are running:

    {{< text bash >}}
    $  kubectl -n istio-system get pod -listio=galley
    NAME                            READY     STATUS    RESTARTS   AGE
    istio-galley-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

1. Verify you’re using Istio version >= 1.0.0. Older version of Galley
   did not properly re-patch the `caBundle`. This typically happened
   when the `istio.yaml` was re-applied, overwriting a previously
   patched `caBundle`.

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -listio=galley -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system exec ${pod} -it /usr/local/bin/galley version| grep ^Version; \
    done
    Version: 1.0.0
    {{< /text >}}

1. Check the Galley pod logs for errors. Failing to patch the
       `caBundle` should print an error.

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -listio=galley -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

1. If the patching failed, verify the RBAC configuration for Galley:

    {{< text bash yaml >}}
    $ kubectl get clusterrole istio-galley-istio-system -o yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      labels:
        app: istio-galley
      name: istio-galley-istio-system
    rules:
    - apiGroups:
      - admissionregistration.k8s.io
      resources:
      - validatingwebhookconfigurations
      verbs:
      - '*'
    - apiGroups:
      - config.istio.io
      resources:
      - '*'
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - '*'
      resourceNames:
      - istio-galley
      resources:
      - deployments
      verbs:
      - get
    {{< /text >}}

    `istio-galley` needs `validatingwebhookconfigurations` write access to
    create and update the `istio-galley` `validatingwebhookconfiguration`.

## Creating configuration fails with `no such hosts` or `no endpoints available` errors

Validation is fail-close. If the `istio-galley` pod is not ready,
configuration cannot be created and updated.  In such cases you’ll see
an error about `no endpoints available`.

Verify the `istio-galley` pod(s) are running and endpoints are ready.

{{< text bash >}}
$  kubectl -n istio-system get pod -listio=galley
NAME                            READY     STATUS    RESTARTS   AGE
istio-galley-5dbbbdb746-d676g   1/1       Running   0          2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istio-galley
NAME           ENDPOINTS                          AGE
istio-galley   10.48.6.108:10514,10.48.6.108:443   3d
{{< /text >}}

If the pods or endpoints aren't ready, check the pod logs and
status for any indication about why the webhook pod is failing to start
and serve traffic.

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -listio=galley -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done
{{< /text >}}

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -listio=galley -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}
