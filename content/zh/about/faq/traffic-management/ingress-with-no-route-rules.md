---
title: 我可以不配置任何路由规则，使用 Ingress 的标准配置吗？
weight: 40
---

简单的 `Ingress` 规范，提供了开箱即用，通过 `Host`,`TLS` 以及基本 `Path` 精确匹配就可以使用，无需配置路由规则。
然而，`Path` 在使用 `Ingress` 资源时不应该有任何 `.` 字符。

比如，下面 `Ingress` 的资源匹配 `Host` 为 `example.com` 以及 `URL` 为 `/helloworld` 的请求。

{{< text bash >}}
$ kubectl create -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
name: simple-ingress
annotations:
  kubernetes.io/ingress.class: istio
spec:
rules:
- host: example.com
  http:
    paths:
    - path: /helloworld
      backend:
        serviceName: myservice
        servicePort: grpc
EOF
{{< /text >}}

然而，这下面的规则将不工作，因为他们在 `Path` 中使用了匹配表达式，并且添加了 `ingress.kubernetes.io` 注解。

{{< text bash >}}
$ kubectl create -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
name: this-will-not-work
annotations:
  kubernetes.io/ingress.class: istio
  # Ingress annotations other than ingress class will not be honored
  ingress.kubernetes.io/rewrite-target: /
spec:
rules:
- host: example.com
  http:
    paths:
    - path: /hello(.*?)world/
      backend:
        serviceName: myservice
        servicePort: grpc
EOF
{{< /text >}}
