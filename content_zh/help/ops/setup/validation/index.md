---
title: 配置验证 Webhook
description: Istio 使用 Kubernetes webhook 进行服务器端配置验证的方式。
weight: 20
---

Galley 的配置验证功能可以对用户编写的 Istio 配置进行验证，确保配置内容在语法和语义上的有效性。Galley 使用了 Kubernetes `ValidatingWebhook`。 `istio-galley` 的 `ValidationWebhookConfiguration` 包含两个 Webhook。

* `pilot.validation.istio.io` - 服务地址路径为  `/admitpilot`，负责验证 Pilot 使用的配置（例如 `VirtualService` 和鉴权相关配置）。

* `mixer.validation.istio.io` - 服务地址路径为 `/admitmixer`，负责验证 Mixer 使用的配置。

两个 Webhook 都在 `istio-galley` 服务的 443 端口上提供服务。每个 webhook 都有自己的 `clientConfig` 、 `namespaceSelector` 和  `rules` 部分。 这两个 Webhook 都适用于所有的命名空间。`namespaceSelector` 应该设置为空。两个规则都适用于 Istio CRD。

## 拒绝了看似正确的配置

手动验证配置是否正确，必要时参考 [Istio API reference](/zh/docs/reference/config)。

## 接受了无效的配置

验证 `istio-galley` `validationwebhookconfiguration` 配置存在并正确。 `apiVersion` 、`apiGroup` 和  `resource` 无效配置的资源应会在两个 `webhooks`  之一的条目中被列出。

{{< text bash yaml >}}
$ kubectl get validatingwebhookconfiguration istio-galley -o yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  labels:
    app: istio-galley
  name: istio-galley
  ownerReferences:
  - apiVersion: extensions/v1beta1
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

如 `validatingwebhookconfiguration` 不存在，则需要验证 `istio-galley-configuration` `configmap` 是否存在。`istio-galley` 使用此 Configmap 中的数据来创建和更新 `validatingwebhookconfiguration`。

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

如果 `istio-galley-configuration` 中的 Webhook 数组为空，且是使用的是 `helm template` 或 `helm install` 的方式，请验证 `--set galley.enabled` 和 `--set global.configValidation=true` 选项是否已经设置。如果没有使用 Helm，就需要找到生成的 YAML，其中包含填充的 Webhook 数组。

`istio-galley` 验证配置是失效关闭（fail-close）的。如果配置存在且范围正确，则 Webhook 将被调用。在资源创建/更新时，如缺少 `caBundle`，错误证书或网络连接问题则会导致错误产生。如果 Webhook 配置正确且没有发现任何错误提示，但是 Webhook 未被调用，则表明集群配置存在错误。

## 创建配置失败并提示 x509 证书错误

`x509: certificate signed by unknown authority` 相关的错误通常因为 Webhook 配置中设置了空的 `caBundle`。验证它是否为空（请参阅[验证 Webhook 配置](#接受了无效的配置)）。`istio-galley` 部署可动态使用保存在 `istio-galley-configuration` `configmap` 中的 Webhook 配置，并且从 `istio-system` 命名空间中保存的  `istio.istio-galley-service-account` 密钥中加载根证书。

1. 验证 `istio-galley` pod 正在运行：

    {{< text bash >}}
    $  kubectl -n istio-system get pod -listio=galley
    NAME                            READY     STATUS    RESTARTS   AGE
    istio-galley-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

1. 确认使用的是 Istio 版本 >= 1.0.0。旧版本的 Galley 不能正确地 re-patch `caBundle`。这种情况通常发生在重新部署 `istio.yaml` 时，需要覆盖之前 patch 过的 `caBundle`。

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -listio=galley -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system exec ${pod} -it /usr/local/bin/galley version| grep ^Version; \
    done
    Version: 1.0.0
    {{< /text >}}

1. 检查 Galley pod 日志是否存在错误。Patch `caBundle` 失败则会打印相关错误。

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -listio=galley -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

1. 如果 Patch 失败，则需验证 Galley 的 RBAC 配置：

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

    `istio-galley` 需要有写入 `validatingwebhookconfigurations` 的权限，以创建和更新 `istio-galley` `validatingwebhook`  配置。

## 创建配置失败，提示 `no such hosts` 或 `no endpoints available` 错误

验证是失败关闭的（fail-close）。如果 `istio-galley` pod 没有准备好，则无法创建和更新相关配置。这种情况下，会提示如下错误： `no such host`（Kubernetes 1.9）或 `no endpoints available`（>=1.10）的错误。

验证 `istio-galley` pod 正在运行且 Endpoint 已准备就绪。

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

如果 Pod 或 Endpoint 尚未就绪，请检查 Pod 日志和状态，以获取有关 Webhook pod 无法启动和提供流量的原因。

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
