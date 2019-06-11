---
title: Sidecar Injection Webhook
description: Describes Istio's use of Kubernetes webhooks for automatic sidecar injection.
weight: 30
---

Automatic sidecar injection adds the sidecar proxy into user-created
pods. It uses a `MutatingWebhook` to append the sidecar’s containers
and volumes to each pod’s template spec during creation
time. Injection can be scoped to particular sets of namespaces using
the webhooks `namespaceSelector` mechanism. Injection can also be
enabled and disabled per-pod with an annotation.

Whether or not a sidecar is injected depends on three pieces of configuration and two security rules:

Configuration:

- webhooks `namespaceSelector`
- default `policy`
- per-pod override annotation

Security rules:

- sidecars cannot be injected in the `kube-system` or `kube-public` namespaces
- sidecars cannot be injected into pods that use the host network

The following truth table shows the final injection status based on
the three configuration items. The security rules above cannot be overridden.

| `namespaceSelector` match | default `policy` | Pod override annotation `sidecar.istio.io/inject` | Sidecar injected? |
|---------------------------|------------------|---------------------------------------------------|-----------|
| yes                       | enabled          | true                                              | yes       |
| yes                       | enabled          | false                                             | no        |
| yes                       | enabled          |                                                   | yes       |
| yes                       | disabled         | true                                              | yes       |
| yes                       | disabled         | false                                             | no        |
| yes                       | disabled         |                                                   | no        |
| no                        | enabled          | true                                              | no        |
| no                        | enabled          | false                                             | no        |
| no                        | enabled          |                                                   | no        |
| no                        | disabled         | true                                              | no        |
| no                        | disabled         | false                                             | no        |
| no                        | disabled         |                                                   | no        |

## The result of sidecar injection was not what I expected

This includes an injected sidecar when it wasn't expected and a lack
of injected sidecar when it was.

1. Ensure your pod is not in the `kube-system` or `kube-public` namespace.
   Automatic sidecar injection will be ignored for pods in these namespaces.

1. Ensure your pod does not have `hostNetwork: true` in its pod spec.
   Automatic sidecar injection will be ignored for pods that are on the host network.

    The sidecar model assumes that the iptables changes required for Envoy to intercept
    traffic are within the pod. For pods on the host network this assumption is violated,
    and this can lead to routing failures at the host level.

1. Check the webhook's `namespaceSelector` to determine whether the
   webhook is scoped to opt-in or opt-out for the target namespace.

    The `namespaceSelector` for opt-in will look like the following:

    {{< text bash yaml >}}
    $ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep "namespaceSelector:" -A5
      namespaceSelector:
        matchLabels:
          istio-injection: enabled
      rules:
      - apiGroups:
        - ""
    {{< /text >}}

    The injection webhook will be invoked for pods created
    in namespaces with the `istio-injection=enabled` label.

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d       enabled
    istio-system   Active    3d
    kube-public    Active    18d
    kube-system    Active    18d
    {{< /text >}}

    The `namespaceSelector` for opt-out will look like the following:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep "namespaceSelector:" -A5
      namespaceSelector:
        matchExpressions:
        - key: istio-injection
          operator: NotIn
          values:
          - disabled
      rules:
      - apiGroups:
        - ""
    {{< /text >}}

    The injection webhook will be invoked for pods created in namespaces
    without the `istio-injection=disabled` label.

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d
    istio-system   Active    3d        disabled
    kube-public    Active    18d       disabled
    kube-system    Active    18d       disabled
    {{< /text >}}

    Verify the application pod's namespace is labeled properly and (re) label accordingly, e.g.

    {{< text bash >}}
    $ kubectl label namespace istio-system istio-injection=disabled --overwrite
    {{< /text >}}

    (repeat for all namespaces in which the injection webhook should be invoked for new pods)

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    {{< /text >}}

1. Check default policy

    Check the default injection policy in the `istio-sidecar-injector` `configmap`.

    {{< text bash yaml >}}
    $ kubectl -n istio-system get configmap istio-sidecar-injector -o jsonpath='{.data.config}' | grep policy:
    policy: enabled
    {{< /text >}}

    Allowed policy values are `disabled` and `enabled`. The default policy
    only applies if the webhook’s `namespaceSelector` matches the target
    namespace. Unrecognized policy values default to `disabled`.

1. Check the per-pod override annotation

    The default policy can be overridden with the
    `sidecar.istio.io/inject` annotation in the _pod template spec’s metadata_.
    The deployment’s metadata is ignored. Annotation value
    of `true` forces the sidecar to be injected while a value of
    `false` forces the sidecar to _not_ be injected.

    The following annotation overrides whatever the default `policy` was
    to force the sidecar to be injected:

    {{< text bash yaml >}}
    $ kubectl get deployment sleep -o yaml | grep "sidecar.istio.io/inject:" -C3
    template:
      metadata:
        annotations:
          sidecar.istio.io/inject: "true"
        labels:
          app: sleep
    {{< /text >}}

## Pods cannot be created at all

Run `kubectl describe -n namespace deployment name` on the failing
pod's deployment. Failure to invoke the injection webhook will
typically be captured in the event log.

### x509 certificate related errors

{{< text plain >}}
Warning  FailedCreate  3m (x17 over 8m)  replicaset-controller  Error creating: Internal error occurred: \
    failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: \
    x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying \
    to verify candidate authority certificate "Kubernetes.cluster.local")
{{< /text >}}

`x509: certificate signed by unknown authority` errors are typically
caused by an empty `caBundle` in the webhook configuration.

Verify the `caBundle` in the `mutatingwebhookconfiguration` matches the
   root certificate mounted in the `istio-sidecar-injector` pod.

{{< text bash >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
$ kubectl -n istio-system get secret istio.istio-sidecar-injector-service-account -o jsonpath='{.data.root-cert\.pem}' | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
{{< /text >}}

The CA certificate should match. If they do not, restart the
sidecar-injector pods.

{{< text bash >}}
$ kubectl -n istio-system patch deployment istio-sidecar-injector \
    -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
deployment.extensions "istio-sidecar-injector" patched
{{< /text >}}

### `no such hosts` or `no endpoints available` errors in deployment status

Injection is fail-close. If the `istio-sidecar-injector` pod is not ready, pods
cannot be created. In such cases you’ll see an error about `no endpoints available`.

{{< text plain >}}
Internal error occurred: failed calling admission webhook "istio-sidecar-injector.istio.io": \
    Post https://istio-sidecar-injector.istio-system.svc:443/admitPilot?timeout=30s: \
    no endpoints available for service "istio-sidecar-injector"
{{< /text >}}

{{< text bash >}}
$  kubectl -n istio-system get pod -listio=sidecar-injector
NAME                            READY     STATUS    RESTARTS   AGE
istio-sidecar-injector-5dbbbdb746-d676g   1/1       Running   0          2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istio-sidecar-injector
NAME           ENDPOINTS                          AGE
istio-sidecar-injector   10.48.6.108:10514,10.48.6.108:443   3d
{{< /text >}}

If the pods or endpoints aren't ready, check the pod logs and status
for any indication about why the webhook pod is failing to start and
serve traffic.

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done

$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}
