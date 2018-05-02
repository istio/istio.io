---
title: Can I use standard Ingress specification without any route rules?
weight: 40
---
{% include home.html %}

Simple ingress specifications, with host, TLS, and exact path based
matches will work out of the box without the need for route
rules. However, note that the path used in the ingress resource should
not have any `.` characters.

For example, the following ingress resource matches requests for the
example.com host, with /helloworld as the URL.

```bash
cat <<EOF | kubectl create -f -
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
```

However, the following rules will not work because it uses regular
expressions in the path and uses `ingress.kubernetes.io` annotations:

```bash
cat <<EOF | kubectl create -f -
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
```
