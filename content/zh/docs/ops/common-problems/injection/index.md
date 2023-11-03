---
title: Sidecar 自动注入问题
description: 解决 Istio 使用 Kubernetes Webhooks 进行 Sidecar 自动注入的常见问题。
force_inline_toc: true
weight: 40
aliases:
  - /zh/docs/ops/troubleshooting/injection
owner: istio/wg-user-experience-maintainers
test: n/a
---

## 注入的结果和预期不一致 {#the-result-of-sidecar-injection-was-not-what-i-expected}

不一致包括 Sidecar 的非预期注入和预期未注入。

1. 确保您的 Pod 不在 `kube-system` 或 `kube-public` 命名空间中。
   这些命名空间中的 Pod 将忽略 Sidecar 自动注入。

1. 确保您的 Pod 在其 Pod 定义中没有 `hostNetwork：true`。
  `hostNetwork：true` 的 Pod 将忽略 Sidecar 自动注入。

    Sidecar 模型假定 iptables 会拦截所有 Pod 中的流量给 Envoy，但是
    `hostNetwork：true` 的 Pod 不符合此假设，并且会导致主机级别的路由失败。

1. 通过检查 webhook 的 `namespaceSelector` 以确定目标命名空间是否包含在 webhook 范围内。

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

    在有 `istio-injection=enabled` 标签的命名空间中创建 Pod 就会调用注入 webhook。

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d       enabled
    istio-system   Active    3d
    kube-public    Active    18d
    kube-system    Active    18d
    {{< /text >}}

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

    在没有标记 `istio-injection=disabled` 标签的命名空间中创建 Pod，注入 webhook 就会被调用。

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d
    istio-system   Active    3d        disabled
    kube-public    Active    18d       disabled
    kube-system    Active    18d       disabled
    {{< /text >}}

    验证应用程序 Pod 的命名空间是否已相应地被正确（重新）标记，例如：

    {{< text bash >}}
    $ kubectl label namespace istio-system istio-injection=disabled --overwrite
    {{< /text >}}

    （对所有需要自动注入 webhook 的命名空间都重复上述步骤）

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    {{< /text >}}

1. 检查默认策略

    在 `istio-sidecar-injector configmap` 中检查默认注入策略。

    {{< text bash yaml >}}
    $ kubectl -n istio-system get configmap istio-sidecar-injector -o jsonpath='{.data.config}' | grep policy:
    policy: enabled
    {{< /text >}}

    策略允许的值为 `disabled` 或者 `enabled`。仅当 webhook 的 `namespaceSelector`
    与目标命名空间匹配时，默认策略才会生效。无法识别的策略值会导致完全禁用注入。

1. 检查每个 Pod 的标签

    可以使用 pod template spec metadata 中的标签 `sidecar.istio.io/inject`
    来覆盖默认策略，如果这样的话，Deployment 相应的 metadata 将被忽略。标签值为
    `true` 会被强制注入 Sidecar，为 `false` 则会强制不注入 Sidecar。

    以下标签会覆盖默认策略并强制注入 Sidecar：

    {{< text bash yaml >}}
    $ kubectl get deployment sleep -o yaml | grep "sidecar.istio.io/inject:" -B4
    template:
      metadata:
        labels:
          app: sleep
          sidecar.istio.io/inject: "true"
    {{< /text >}}

## Pod 不能创建 {#pods-cannot-be-created-at-all}

在失败的 Pod 的 Deployment 上运行 `kubectl describe -n namespace deployment name`。
通常能在事件中看到调用注入 webhook 失败的原因。

### x509 证书相关的错误 {#x509-certificate-related-errors}

{{< text plain >}}
Warning  FailedCreate  3m (x17 over 8m)  replicaset-controller  Error creating: Internal error occurred: \
    failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: \
    x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying \
    to verify candidate authority certificate "Kubernetes.cluster.local")
{{< /text >}}

`x509: certificate signed by unknown authority` 错误通常由 webhook
配置中的空 `caBundle` 引起。

验证 `mutatingwebhookconfiguration` 配置中的 `caBundle` 是否与
`istio-sidecar-injector` 中 Pod 安装的根证书匹配。

{{< text bash >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
$ kubectl -n istio-system get configmap istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | base64 -w 0 | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
{{< /text >}}

CA 证书必须匹配，否则需要重新启动 sidecar-injector Pod。

{{< text bash >}}
$ kubectl -n istio-system patch deployment istio-sidecar-injector \
    -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
deployment.extensions "istio-sidecar-injector" patched
{{< /text >}}

### Deployment 状态中出现 `no such hosts` 或 `no endpoints available` {#no-such-hosts-or-no-endpoints-available-errors-in-deployment-status}

注入是失效关闭的（fail-close）。如果 `istio-sidecar-injector` Pod 尚未准备就绪，
则无法创建 Pod。在这种情况下，则会出现 `no endpoints available`。

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
istio-sidecar-injector   10.48.6.108:15014,10.48.6.108:443   3d
{{< /text >}}

如果 Pod 或 endpoint 尚未准备就绪，可以通过检查 Pod 日志和状态查找有关
Webhook Pod 无法启动的原因。

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done

$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}

## 如果 Kubernetes API server 有代理设置的话，Sidecar 的自动注入功能是不能用的 {#automatic-sidecar-injection-fails-if-the-Kubernetes-API-server-has-proxy-settings}

当 Kubernetes API server 包含诸如以下的代理设置时：

{{< text yaml >}}
env:
  - name: http_proxy
    value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
    value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
    value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
{{< /text >}}

使用这些设置，Sidecar 自动注入就会失败。相关的报错可以在 `kube-apiserver`
日志中找到：

{{< text plain >}}
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
{{< /text >}}

根据 `*_proxy` 相关的环境变量设置，确保 Pod 和 service CIDR 是没有被代理的。检查
`kube-apiserver` 的运行日志验证是否有请求正在被代理。

一种解决方法是在 `kube-apiserver` 的配置中删除代理设置，另一种解决方法是把
`istio-sidecar-injector.istio-system.svc` 或者 `.svc` 加到 `no_proxy`
的 `value` 里面。每种解决方法都需要重新启动 `kube-apiserver`。

Kubernetes 与此有关的一个 [issue](https://github.com/kubernetes/kubeadm/issues/666)
已被 [PR #58698](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)
解决。

## 在 Pod 中使用 `tcpdump` 的限制 {#limitations-for-using-Tcpdump-in-pods}

`tcpdump` 在 Sidecar 中不能工作 - 因为该容器不以 root 身份运行。但是由于同一
Pod 内容器的网络命名空间是共享的，因此 Pod 中的其他容器也能看到所有数据包。
`iptables` 也能查看到 Pod 级别的相关配置。

Envoy 和应用程序之间的通信是通过 127.0.0.1 进行的，这个通讯过程未加密。

## 集群不会自动缩小 {#cluster-is-not-scaled-down-automatically}

由于 Sidecar 容器安装了本地存储卷，因此节点自动缩放器无法使用注入的
Pod 驱逐节点。这是一个[已知的问题](https://github.com/istio/istio/issues/19395)。
解决方法是向 Pod 添加注解 `"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"`。

## 如果 istio-proxy 还没有准备好，Pod 或容器会出现网络问题 {#pod-or-containers-start-with-network-issues-if-istio-proxy-is-not-ready}

许多应用程序在启动期间执行一些需要网络连接命令或检查。此时如果 istio-proxy
Sidecar 容器没有准备好，可能会导致应用程序容器挂起或重新启动。

要避免这种情况，可以将 `holdApplicationUntilProxyStarts` 设置为 `true`。
这将会使 Sidecar 注入器在 Pod 的容器列表中的容器启动之前注入 Sidecar，
并阻止所有其它容器的启动，直到代理就绪。

这可以作为全局配置选项添加：

{{< text yaml >}}
values.global.proxy.holdApplicationUntilProxyStarts: true
{{< /text >}}

或者在 Pod 的 annotation 中添加：

{{< text yaml >}}
proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
{{< /text >}}
