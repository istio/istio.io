---
title: 配置验证的问题
description: 如何解决配置验证的问题。
force_inline_toc: true
weight: 50
aliases:
    - /zh/help/ops/setup/validation
    - /zh/help/ops/troubleshooting/validation
    - /zh/docs/ops/troubleshooting/validation
owner: istio/wg-user-experience-maintainers
test: no
---

## 看似有效的配置不生效 {#valid-configuration-is-rejected}

使用 [istioctl validate -f](/zh/docs/reference/commands/istioctl/#istioctl-validate)
以及 [istioctl analyze](/zh/docs/reference/commands/istioctl/#istioctl-analyze)
来获取更多为什么配置不生效的信息。使用和控制面版本相似的 **istioctl** CLI。

最常见的配置问题是关于 YAML 文件空格缩进以及数组符号（`-`）的错误。

手动验证您的配置是否正确，当有必要的时候请参照 [Istio API 文档](/zh/docs/reference/config)。

## 接受无效配置 {#invalid-configuration-is-accepted}

验证存在正确的名为 `istio-validator-` 且后跟 `<revision>-` 的 `validatingwebhookconfiguration`，
如果不是默认的修订版则后跟 Istio 系统命名空间（例如 `istio-validator-myrev-istio-system`）。
有效配置的 `apiVersion`、`apiGroup` 和 `resource` 应列举在 `validatingwebhookconfiguration`
的 `webhooks` 部分。

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
    # caBundle 应该是非空的。webhook
    # 服务使用已安装服务帐户密码中的 ca-cert
    # 每隔一秒定期（重新）修订一次。
    caBundle: LS0t...
    # service 对应实现 webhook 的 Kubernetes 服务
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

如果 `istio-validator-` webhook 不存在，那就验证 `global.configValidation`
安装选项是否被设为 `true`。

校验配置如果失败会自动关闭。如果配置存在且作用范围正确，webhook 将被调用。
在资源创建或更新的时候，如果 `caBundle` 缺失或证书错误，亦或网络连接问题都将会导致报错。
如果您确信您的配置没有问题，webhook 没有被调用却看不到任何错误信息，您的集群配置肯定有问题。

## 创建配置失败报错：x509 certificate errors {#x509-certificate-errors}

`x509: certificate signed by unknown authority` 错误通常和 webhook
配置中的空 `caBundle` 有关，所以要确认它不为空
（请查阅[验证 webhook 配置](#invalid-configuration-is-accepted)）。
Istio 有意识地使用 `istio-validation` `configmap` 和根证书，调整了
webhook 配置。

1. 验证 `istio-pilot` Pod 是否在运行：

    {{< text bash >}}
    $  kubectl -n istio-system get pod -lapp=istiod
    NAME                            READY     STATUS    RESTARTS   AGE
    istiod-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

1. 检查 Pod 日志是否有错误，修复 `caBundle` 失败的时候会报错：

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

1. 如果修复失败，请验证 Istiod 的 RBAC 配置：

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

    Istio 需要 `validatingwebhookconfigurations` 的写权限来创建和更新 `validatingwebhookconfiguration` 配置项。

## 创建配置报错：`no such hosts` 或 `no endpoints available` {#creating-configuration-fail}

校验失败自动关闭。如果 `istiod` Pod 没有准备就绪，
配置是不会被创建或者更新的，在下面的例子里您可以看到关于
`no endpoints available` 的错误信息。

检查 `istiod` Pod 是否运行，并且检查 endpoint 是否准备就绪。

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

如果 Pod 或者 endpoint 尚未准备就绪，请检查 Pod 日志和任何导致
webhook Pod 无法启动的异常状态以及服务流量。

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
