---
title: 可以使用标准的 ingress 规范而不使用任何路由规则吗？
weight: 40
---

简单的 ingress 规范，包括主机，TLS 和基于路径的精确匹配，无需路由规则即可正常工作。但需要注意，ingress 资源中使用的路径不能包含任何 “.” 字符。

例如，以下 ingress 资源匹配 example.com 主机的请求，其中 /helloworld 为 URL。

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

但是，以下的规则不能正常工作，因为在路径和 `ingress.kubernetes.io` 注释中使用了正则表达式：

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
