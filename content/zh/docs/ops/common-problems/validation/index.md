---
title: 配置验证的问题
description: 如何解决配置验证的问题。
force_inline_toc: true
weight: 50
aliases:
    - /zh/help/ops/setup/validation
    - /zh/help/ops/troubleshooting/validation
    - /zh/docs/ops/troubleshooting/validation
---

## 看似有效的配置不生效 {#valid-configuration-is-rejected}

手动验证您的配置是否正确，当有必要的时候请参照 [Istio API 文档](/zh/docs/reference/config) 。

## 接受无效配置 {#invalid-configuration-is-accepted}

验证 `istiod-istio-system` `validationwebhookconfiguration` 配置是否存在并且是正确的。无效的 `apiVersion`、`apiGroup` 和 `resource` 配置应该在两个 `webhook` 其中之一被列举出来。

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
      name: istio-istiod
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

如果 `validatingwebhookconfiguration` 不存在，那就验证
`istio-validation` `configmap` 是否存在。Istio 使用 configmap 的数据来创建或更新 `validatingwebhookconfiguration`。

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

如果 `istio-validation` 中的 webhook 数组为空，则校验 `global.configValidation` 安装选项是否被设置。

校验配置如果失败会自动关闭，正常情况下配置存在并校验通过，webhook 将被调用。在资源创建或更新的时候，如果缺失 `caBundle`或者错误的证书，亦或网络连接问题都将会导致报错。如果你确信你的配置没有问题，webhook 没有被调用却看不到任何错误信息，你的集群配置肯定有问题。

## 创建配置失败报错： x509 certificate errors {#x509-certificate-errors}

`x509: certificate signed by unknown authority` 错误通常和 webhook 配置中的空 `caBundle` 有关，所以要确认它不为空 (请查阅[验证 webhook 配置](#invalid-configuration-is-accepted))。Istio 有意识的使用 `istio-validation` `configmap` 和根证书，调整了 webhook 配置。

1. 验证 `istio-pilot` pod  是否在运行：

    {{< text bash >}}
    $  kubectl -n istio-system get pod -lapp=pilot
    NAME                            READY     STATUS    RESTARTS   AGE
    istio-pilot-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

1. 检查 pod 日志是否有错误，修复 `caBundle` 失败的时候会报错：

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -lapp=pilot -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

1. 如果修复失败，请验证 Pilot 的 RBAC 配置：

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

    Istio 需要 `validatingwebhookconfigurations` 的写权限来创建和更新 `istio-galley validatingwebhookconfiguration` 配置项。

## 创建配置报错：`no such hosts` 、 `no endpoints available` {#creating-configuration-fail}

如果 `istio-pilot` pod 没有准备就绪，配置是不会被创建或者更新的，在下面的例子里您可以看到关于 `no endpoints available` 的错误信息。

检查 `istio-pilot` pod 是否运行，并且检查 endpoint 是否准备就绪。

{{< text bash >}}
$ kubectl -n istio-system get pod -lapp=pilot
NAME                            READY     STATUS    RESTARTS   AGE
istio-pilot-5dbbbdb746-d676g   1/1       Running   0          2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istio-pilot
NAME           ENDPOINTS                          AGE
istio-pilot   10.48.6.108:15014,10.48.6.108:443   3d
{{< /text >}}

如果 pod 或者 endpoint 尚未准备就绪，请检查 pod log 和任何导致 webhook pod 无法启动的异常状态，以及服务流量。

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=pilot -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done
{{< /text >}}

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=pilot -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}
