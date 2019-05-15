---
title: Sidecar 注入 Webhook
description: 描述了 Istio 如何使用 Kubernetes webhooks 进行自动 sidecar 注入。
weight: 30
---

自动 Sidecar 注入可将 Sidecar 代理添加到用户创建的 Pod 之中。在创建 Pod 时，它使用 `MutatingWebhook` 将 Sidecar 容器和卷附加到每个 Pod 的中。可以使用 Webhook 的`namespaceSelector` 机制将注入范围限定为特定的命名空间，也可以使用注解为每个 Pod 启用和禁用注入。

是否进行 Sidecar 注入取决于以下三个条件：

* Webhook 的 `namespaceSelector`

* 默认 `Policy`

* 每个 Pod 的注解

下面的表格展示了基于三个条件变量的最终的注入状态。

| `namespaceSelector` 匹配 | 默认 `Policy` | Pod 注解 `sidecar.istio.io/inject` | Sidecar 是否注入? |
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

## 注入的结果和预期不一致

不一致包括 Sidecar 的非预期注入和非预期未注入。

1. 通过检查 Webhook 的 `namespaceSelector` 以确定目标命名空间是否包含或者排除在 `Webhook` 范围内。

    用包含方式定义的 `namespaceSelector` 如下所示：

    {{< text bash yaml >}}
    $ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep "namespaceSelector:" -A5
      namespaceSelector:
        matchLabels:
          istio-injection: enabled
      rules:
      - apiGroups:
        - ""
    {{< /text >}}

    在标记 `istio-injection=enabled` 标签的命名空间中创建的 Pod，就会调用 Webhook。

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d       enabled
    istio-system   Active    3d
    kube-public    Active    18d
    kube-system    Active    18d
    {{< /text >}}

    用排除方式定义的 `namespaceSelector` 如下所示：

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

    在没有标记 `istio-injection=disabled` 标签的命名空间中创建的 Pod，会调用 Webhook 进行注入。

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

    （在所有应该执行 Webhook 注入的命名空间中执行这一命令）

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    {{< /text >}}

1. 检查默认 `policy`

    检查 `istio-sidecar-injector` `configmap` 中的默认注入策略。

    {{< text bash yaml >}}
    $ kubectl -n istio-system get configmap istio-sidecar-injector -o jsonpath='{.data.config}' | grep policy:
    policy: enabled
    {{< /text >}}

    策略允许的取值范围是 `disabled` 和 `enabled`。仅当 webhook 的 `namespaceSelector` 与目标命名空间匹配时，默认策略才会被应用。无法识别的策略值默认为 `disabled`。

1. 检查每个 Pod 的注解。

    可以使用 Pod 注解 `sidecar.istio.io/inject` 来覆盖默认策略。`Deployment` 的 `metadata` 在这里是无效的。注解值为 `true` 会被强制注入 Sidecar，为 `false` 不会注入 Sidecar。

    以下注解会覆盖默认策略并强制注入 Sidecar：

    {{< text bash yaml >}}
    $ kubectl get deployment sleep -o yaml | grep "sidecar.istio.io/inject:" -C3
    template:
      metadata:
        annotations:
          sidecar.istio.io/inject: "true"
        labels:
          app: sleep
    {{< /text >}}

## Pod 完全不能创建

在失败的 Pod 的部署上运行 `kubectl describe -n namespace deployment name`。通常能在事件日志中获取到调用注入 Webhook 失败的原因。

### x509 证书相关的错误

{{< text plain >}}
Warning  FailedCreate  3m (x17 over 8m)  replicaset-controller  Error creating: Internal error occurred: \
    failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: \
    x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying \
    to verify candidate authority certificate "Kubernetes.cluster.local")
{{< /text >}}

`x509: certificate signed by unknown authority` 错误通常是因为 Webhook 中配置了空的 `caBundle`。

验证 `mutatingwebhookconfiguration` 配置中的 `caBundle` 是否与 `istio-sidecar-injector` 中 Pod 安装的根证书匹配。

{{< text bash >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
$ kubectl -n istio-system get secret istio.istio-sidecar-injector-service-account -o jsonpath='{.data.root-cert\.pem}' | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
{{< /text >}}

CA 证书必须匹配。如不匹配，则可重新启动 `sidecar-injector` Pod。

{{< text bash >}}
$ kubectl -n istio-system patch deployment istio-sidecar-injector \
    -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
deployment.extensions "istio-sidecar-injector" patched
{{< /text >}}

### 部署状态中出现 `no such hosts` 或 `no endpoints available` 错误

注入过程是`故障则关闭`的（fail-close）。如果 `istio-sidecar-injector` Pod 尚未准备就绪，则无法创建 Pod。在这种情况下，则会出现以下错误 `no such host` （Kubernetes 1.9）或 `no endpoints available`（>=1.10）。

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

如果 Pod 或 Endpoint 尚未就绪，可以通过检查 Pod 日志和状态查找有关 Webhook pod 无法启动并提供服务的原因。

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done

$ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}