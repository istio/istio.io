---
title: 为什么我的 CORS 配置不起作用？
weight: 40
---

当应用了 [CORS 配置](/zh/docs/reference/config/networking/virtual-service/#CorsPolicy)后，您可能会发现看似什么也没发生，并想知道哪里出了问题。
CORS 是一个经常被误解的 HTTP 概念，在配置时经常会导致混淆。

要弄明白这个问题，有必要退后一步，看看 [CORS 是什么](https://developer.mozilla.org/zh/docs/Web/HTTP/CORS)，以及何时应该使用它。
默认情况下，浏览器对脚本发起的 "cross origin" 请求有限制。
例如，这可以防止网站 `attack.example.com` 向 `bank.example.com` 发出 JavaScript 请求，从而窃取用户的敏感信息。

为了允许这个请求， `bank.example.com` 必须允许 `attack.example.com` 执行跨源请求。
这就是 CORS 的作用所在。如果我们想在一个启用了 Istio 的集群内提供 `bank.example.com` 服务，我们可以通过配置一个 `corsPolicy` 来允许这样做：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bank
spec:
  hosts:
  - bank.example.com
  http:
  - corsPolicy:
      allowOrigins:
      - exact: https://attack.example.com
...
{{< /text >}}

在这种情况下，我们明确地允许一个单一的起源；通配符通常用于不敏感的页面。

一旦我们这样做了，一个常见的错误就是发送一个请求，比如 `curl bank.example.com -H "Origin: https://attack.example.com"`,然后期望这个请求被拒绝。
但是，curl 和许多其他客户端不会看到被拒绝的请求，因为 CORS 是一个浏览器约束。
CORS 配置只是在响应中添加 `Access-Control-*` 头；如果响应不令人满意，则由客户端（浏览器）来拒绝请求。
在浏览器中，这是通过[预检请求](https://developer.mozilla.org/zh/docs/Web/HTTP/CORS#preflighted_requests)来完成的。
