---
title: Galley 的配置问题
description: 如何解决 Galley 的配置问题。
force_inline_toc: true
weight: 50
aliases:
    - /zh/help/ops/setup/validation
    - /zh/help/ops/troubleshooting/validation
    - /zh/docs/ops/troubleshooting/validation
---

## 看似有效的配置不生效 {#valid-configuration-is-rejected}

手动验证您的配置是否正确，当有必要的时候请参照[Istio API 文档](/zh/docs/reference/config) 。

## 接受无效配置 {#invalid-configuration-is-accepted}

验证 `istio-galley`和`validationwebhookconfiguration` 配置是否存在并且是正确的。 无效的 `apiVersion`、 `apiGroup`和 `resource` 配置应该在两个 `webhook` 其中之一被列举出来。

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

如果 `validatingwebhookconfiguration` 不存在，那就验证
`istio-galley-configuration` `configmap` 是否存在。`istio-galley` 使用 configmap 的数据来创建或更新 `validatingwebhookconfiguration`。

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

如果 `istio-galley-configuration` 中的 webhook 数组为空，校验 `galley.enabled` 和 `global.configValidation` 安装选项是否被设置。

`istio-galley` 校验配置如果失败会自动关闭，正常情况下配置存在并校验通过，webhook 将被调用。在资源创建或更新的时候，如果缺失 `caBundle`或者错误的证书，亦或网络连接问题都将会导致报错。如果你确信你的配置没有问题，webhook 没有被调用却看不到任何错误信息，你的集群配置肯定有问题。

## 创建配置失败报错： x509 certificate errors {#x509-certificate-errors}

`x509: certificate signed by unknown authority` 错误通常和 webhook 配置中的空 `caBundle` 有关，所以要确认它不为空 (请查阅 [验证 webhook 配置](#invalid-configuration-is-accepted))。在部署 `istio-galley` 的时候要有意识地调整 webhook 配置，使用 `istio-galley-configuration` `configmap` 和安装自 `istio-system` 命名空间私有 `istio.istio-galley-service-account` 的根证书。

1. 验证 `istio-galley` pod  是否在运行：

    {{< text bash >}}
    $  kubectl -n istio-system get pod -listio=galley
    NAME                            READY     STATUS    RESTARTS   AGE
    istio-galley-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

1. 确认您使用的 Istio 版本 >= 1.0.0 。旧版本的 Galley 并没有重新修复 `caBundle`。这通常发生在重新使用 `istio.yaml` 时，覆盖了以前已经修复的 `caBundle` 。

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -listio=galley -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system exec ${pod} -it /usr/local/bin/galley version| grep ^Version; \
    done
    Version: 1.0.0
    {{< /text >}}

1. 检查 Galley pod 日志是否有错误，修复 `caBundle` 失败的时候会报错：

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -listio=galley -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

1. 如果修复失败，请验证 Galley 的 RBAC 配置：

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

    `istio-galley` 需要 `validatingwebhookconfigurations` 的权限来创建和更新 `istio-galley` `validatingwebhookconfiguration` 配置项。

## 创建配置报错：`no such hosts` 、 `no endpoints available` {#creating-configuration-fail}

如果 `istio-galley` pod 没有准备就绪，配置是不会被创建或者更新的，在下面的例子里您可以看到关于 `no endpoints available` 的错误信息。

检查 `istio-galley` pod 是否运行，并且检查 endpoint 是否准备就绪。

{{< text bash >}}
$  kubectl -n istio-system get pod -listio=galley
NAME                            READY     STATUS    RESTARTS   AGE
istio-galley-5dbbbdb746-d676g   1/1       Running   0          2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istio-galley
NAME           ENDPOINTS                          AGE
istio-galley   10.48.6.108:15014,10.48.6.108:443   3d
{{< /text >}}

如果 pod 或者 endpoint 尚未准备就绪，请检查 pod log 和任何导致 webhook pod 无法启动的异常状态，以及服务流量。

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
