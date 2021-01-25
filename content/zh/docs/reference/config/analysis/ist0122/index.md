---
title: InvalidRegexp
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 Istio 的资源字段为正则，且其存储了一个非法的正则表达式时，会出现此消息。

Istio 正则表达式使用 [RE2](https://github.com/google/re2/wiki/Syntax) 语法规范.

## 示例{#example}

当集群包含以下资源时:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bad-match
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        regex: "[A-Z"
    route:
    - destination:
        host: productpage
{{< /text >}}

您就会收到这条消息:

{{< text plain >}}
Warning [IST0122] (VirtualService bad-match.default) Field "uri" regular expression invalid: "[A-Z" (error parsing regexp: missing closing ]: `[A-Z`)
{{< /text >}}

在这个样例中, 正则表达式 `[A-Z` 没有遵循 RE2 规范.
