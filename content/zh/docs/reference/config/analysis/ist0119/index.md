---
title: JwtFailureDueToInvalidServicePortPrefix
layout: analysis-message
---

当认证策略指定使用 JWT 认证但目标 [Kubernetes 服务](https://kubernetes.io/docs/concepts/services-networking/service/)配置不正确时，会出现此消息。
正确定位到 Kubernetes 服务需要使用 http|http2|https 前缀来命名端口（请参见[协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/)），并且还需要协议使用 TCP；协议留空也可以，因为其默认值就是 TCP。

## 示例{#example}

当您的集群有如下策略：

{{< text yaml >}}
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: secure-httpbin
  namespace: default
spec:
  targets:
    - name: httpbin
  origins:
    - jwt:
        issuer: "testing@secure.istio.io"
        jwksUri: "https://raw.githubusercontent.com/istio/istio-1.4/security/tools/jwt/samples/jwks.json"
{{< /text >}}

它的目标服务如下：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: default
  labels:
    app: httpbin
spec:
  ports:
  - name: svc-8080
    port: 8080
    targetPort: 80
    protocol: TCP
  selector:
    app: httpbin
{{< /text >}}

您就会收到这条消息：

{{< text plain >}}
Warn [IST0119] (Policy secure-httpbin.default) Authentication policy with JWT targets Service with invalid port specification (port: 8080, name: svc-8080, protocol: TCP, targetPort: 80).
{{< /text >}}

在这个例子中，端口名为 `svc-8080`，没有遵循 `name: <http|https|http2>[-<suffix>]` 这种格式。

## 如何解决{#how-to-resolve}

- JWT 认证只支持 http、https 或 http2。将服务的端口重命名为 `<http|https|http2>[-<suffix>]` 这种格式即可。
