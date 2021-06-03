---
title: NoMatchingWorkloadsFound
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 `AuthorizationPolicy` 资源的选择器匹配不到任何 Pod 时，会出现此消息。

## 示例{#example}

当集群包含以下资源时:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-nopods
  namespace: httpbin
spec:
  selector:
    matchLabels:
      app: bogus-label # Bogus label. No matching workloads
      version: v1
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/default/sa/sleep"]
        - source:
            namespaces: ["httpbin"]
      to:
        - operation:
            methods: ["GET"]
            paths: ["/info*"]
        - operation:
            methods: ["POST"]
            paths: ["/data"]
      when:
        - key: request.auth.claims[iss]
          values: ["https://accounts.google.com"]
{{< /text >}}

您会收到此消息：

{{< text plain >}}
Warning [IST0127] (AuthorizationPolicy httpbin-nopods.httpbin) No matching workloads for this resource with the following labels: app=bogus-label,version=v1
{{< /text >}}

在这个样例中, `AuthorizationPolicy` 资源 `httpbin-nopods` 需要绑定到包含 `app=bogus-label` 标签的 Pod 上，但是其不存在。

## 如何修复{#how-to-resolve}

- 修改选择器 `selector` 以选择存在的 Pod
- 修改特定 Pod 的标签以匹配此资源的选择器
