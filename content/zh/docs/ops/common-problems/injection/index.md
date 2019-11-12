---
title: Sidecar 自动注入问题
description: 解决 Istio 使用 Kubernetes Webhooks 进行 sidecar 自动注入的常见问题。
force_inline_toc: true
weight: 40
aliases:
  - /zh/docs/ops/troubleshooting/injection
---

## 注入的结果和预期不一致{#the-result-of-sidecar-injection-was-not-what-i-expected}

不一致包括 sidecar 的非预期注入和未预期注入。

1. 确保您的 Pod 不在 `kube-system` 或`kube-public` 名称空间中。这些命名空间中的 Pod 将忽略 Sidecar 自动注入。

1. Ensure your pod does not have `hostNetwork: true` in its pod spec.
   Automatic sidecar injection will be ignored for pods that are on the host network.

    The sidecar model assumes that the iptables changes required for Envoy to intercept
    traffic are within the pod. For pods on the host network this assumption is violated,
    and this can lead to routing failures at the host level.

确保您的 Pod 在其 Pod 定义中没有 `hostNetwork：true`。`hostNetwork：true` 的 Pod 将忽略 Sidecar 自动注入。
     sidecar 模型假定 iptables 发生变化，使 Envoy 能够拦截
     在 pod 内的流量。 对于 `hostNetwork：true` 的 Pod 此假设已被违反，
     这会导致主机级别的路由失败。

1. Check the webhook's `namespaceSelector` to determine whether the
   webhook is scoped to opt-in or opt-out for the target namespace.
   通过检查 webhook 的 `namespaceSelector` 以确定目标命名空间是否包含或者排除在 webhook 范围内。

    包含在范围内的 `namespaceSelector` 如下所示：

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
    在标记 `istio-injection=enabled` 标签的命名空间中创建的 pod，则注入 webhook 会被调用。

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d       enabled
    istio-system   Active    3d
    kube-public    Active    18d
    kube-system    Active    18d
    {{< /text >}}

    The `namespaceSelector` for opt-out will look like the following:
    不包含在注入范围的 `namespaceSelector` 如下所示：

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
    在没有标记 `istio-injection=disabled` 标签的命名空间中创建的 pod，则注入 webhook 会被调用。

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d
    istio-system   Active    3d        disabled
    kube-public    Active    18d       disabled
    kube-system    Active    18d       disabled
    {{< /text >}}

    Verify the application pod's namespace is labeled properly and (re) label accordingly, e.g.
    验证应用程序 pod 的命名空间是否已相应地被正确（重新）标记，例如：

    {{< text bash >}}
    $ kubectl label namespace istio-system istio-injection=disabled --overwrite
    {{< /text >}}

    (repeat for all namespaces in which the injection webhook should be invoked for new pods)
    （重复 pod 创建时调用注入 webhook 的所有命名空间）

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
    namespace. Unrecognized policy causes injection to be disabled completely.

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

## Pods 不能创建{#pods-cannot-be-created-at-all}

在失败的 pod 的 deployment 上运行 `kubectl describe -n namespace deployment name`。通常能在事件中看到调用注入 webhook 失败的原因。

### x509 证书相关的错误{#x509-certificate-related-errors}

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

### deployment 状态中出现 `no such hosts` 或 `no endpoints available`{#no-such-hosts-or-no-endpoints-available-errors-in-deployment-status}

注入是失效关闭的（fail-close）。如果 `istio-sidecar-injector` pod 尚未准备就绪，则无法创建 pod。在这种情况下，则会出现 `no endpoints available`。

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

如果 pod 或 endpoint 尚未准备就绪，可以通过检查 pod 日志和状态查找有关 webhook pod 无法启动的原因。

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done

$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}

## Automatic sidecar injection fails if the Kubernetes API server has proxy settings{#automatic-sidecar-injection-fails-if-the-kubernetes-api-server-has-proxy-settings}

When the Kubernetes API server includes proxy settings such as:

{{< text yaml >}}
env:
  - name: http_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
  value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
{{< /text >}}

With these settings, Sidecar injection fails. The only related failure log can be found in `kube-apiserver` log:

{{< text plain >}}
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
{{< /text >}}

Make sure both pod and service CIDRs are not proxied according to `*_proxy` variables.  Check the `kube-apiserver` files and logs to verify the configuration and whether any requests are being proxied.

One workaround is to remove the proxy settings from the `kube-apiserver` manifest, another workaround is to include `istio-sidecar-injector.istio-system.svc` or `.svc` in the `no_proxy` value. Make sure that `kube-apiserver` is restarted after each workaround.

An [issue](https://github.com/kubernetes/kubeadm/issues/666) was filed with Kubernetes related to this and has since been closed.
[https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)

## 在 pods 中使用 Tcpdump 的限制{#limitations-for-using-tcpdump-in-pods}

Tcpdump doesn't work in the sidecar pod - the container doesn't run as root. However any other container in the same pod will see all the packets, since the
network namespace is shared. `iptables` will also see the pod-wide configuration.

Communication between Envoy and the app happens on 127.0.0.1, and is not encrypted.
