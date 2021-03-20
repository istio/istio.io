---
title: MTLSPolicyConflict
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当目标规则和策略资源与双向 TLS 发生冲突时，会出现此消息。
如果这两个资源各自指定的双向 TLS 模式不兼容，则它们会冲突。
此冲突意味着与目标规则匹配的到达指定主机的流量将被拒绝。

此消息仅会在不使用[自动双向 TLS](/zh/docs/tasks/security/authentication/auto-mtls/) 的服务网格上发生。

## 示例{#an-example}

考虑使用以下 `MeshPolicy` 的 Istio 网格：

{{< text yaml >}}
apiVersion: authentication.istio.io/v1alpha1
kind: MeshPolicy
metadata:
  name: default
spec:
  peers:
  - mtls: {}
{{< /text >}}

该策略资源的效果是，所有服务都需要使用双向 TLS 认证策略。
但是，请注意，如果没有相应的目标规则要求流量使用双向 TLS，流量将在不使用双向 TLS 的情况下被发送到服务。
此冲突意味着，目的地为网格中的服务的流量将最终失败。

此示例中，您可以通过以下两种方式之一解决此问题：
您可以降低网格策略的双向 TLS 要求以接收明文流量（可能需要完全删除网格策略），
或者可以创建相应的目标规则以要求网格内的流量使用双向 TLS：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: mtls-for-cluster
spec:
  host: *.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
{{< /text >}}

## 哪些目标规则和策略与服务有关{#which-destination-rules-and-policies-are-relevant-to-a-service}

为了有效解决双向 TLS 冲突，加深对目标规则和策略是如何影响到达服务的流量的理解会很有帮助。
考虑一个在 `my-namespace` 命名空间中的 `my-service` 示例服务。
要确定哪个策略对象应用于 `my-service`，以下资源将按序匹配：

1. 在命名空间 `my-namespace` 中，指定 `target` 为 `my-service` 的策略。
1. 在命名空间 `my-namespace` 中，名为 `default` 且没有定义 `target` 的策略。这样的策略隐式的应用于整个命名空间。
1. 名为 `default` 的网格策略资源。

要确定哪些目标规则被应用于发送到 `my-service` 的流量，我们首先必须知道流量来自哪个命名空间。
本例中，我们假设这个命名空间为 `other-namespace`。
目标规则按照下面的顺序进行匹配：

1. 命名空间 `other-namespace` 中，匹配主机 `my-service.my-namespace.svc.cluster.local` 的目标规则，
   这可能是完全匹配或通配符匹配。还要注意，控制配置资源可见性的 `exportTo` 字段将被忽略，因为与源服务相同的命名空间中的资源始终可见。
1. 命名空间 `my-namespace` 中，匹配主机 `my-service.my-namespace.svc.cluster.local` 的目标规则，
   这可能是完全匹配或通配符匹配。请注意，`exportTo` 字段必须定义此资源为公共资源（例如，它取值为`"*"`或未指定），以便进行匹配。
1. 根命名空间（默认为 `istio-system`）中匹配主机 `my-service.my-namespace.svc.cluster.local` 的目标规则。
   根命名空间由 [`MeshConfig` 资源](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) 的 `rootNamespace` 属性控制。请注意，`exportTo` 字段必须定义此资源为公共资源（例如，它取值为`"*"`或未指定），以便进行匹配。

最后请注意，遵循这些规则时，Istio 不会应用任何继承概念。第一个符合匹配条件的资源将被使用。

## 如何处理{#how-to-resolve}

检查输出信息，您将看到类似下面的信息：

{{< text plain >}}
Error [IST0113] (DestinationRule default-rule.istio-system) A DestinationRule
and Policy are in conflict with regards to mTLS for host
myhost.my-namespace.svc.cluster.local:8080. The DestinationRule
"istio-system/default-rule" specifies that mTLS must be true but the Policy
object "my-namespace/my-policy" specifies Plaintext.
{{< /text >}}

此消息中包含两个冲突的资源：

* 策略资源 `my-namespace/my-policy`，它指定 `Plaintext` 作为其支持的双向 TLS 模式。
* 目标规则 `istio-system/default-rule`，它要求到达 `myhost.my-namespace.svc.cluster.local:8080` 主机的流量使用双向 TLS。

您可以通过执行以下任一操作来解决冲突：

* 修改策略资源 `my-namespace/my-policy` 以将双向 TLS 作为身份验证模式。
  通常，可以通过在资源中添加一个 `peer` 属性来实现，其子属性为 `mtls`。您可以在
  [策略对象参考](/zh/docs/reference/config/security/istio.authentication.v1alpha1/#Policy)中阅读有关策略对象的更多信息。
* 修改目标规则 `istio-system/default-rule`，删除 `ISTIO_MUTUAL` 以不使用双向 TLS。
  请注意，`default-rule` 在 `istio-system` 命名空间中，
  默认情况下 `istio-system` 命名空间被认为是配置的根命名空间（尽管可以通过资源中的 `rootNamespace` 属性来覆盖它）。
  这意味着此目标规则可能会影响网格中的所有其他服务。
* 在与服务所在同一命名空间（本例中为 `my-namespace`）中，添加新的目标规则，并且不要将流量策略定义为 `ISTIO_MUTUAL`。
  由于此规则与服务位于同一命名空间中，因此它将覆盖全局目标规则 `istio-system/default-rule`。
