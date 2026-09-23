---
title: Чи можу я використовувати стандартну специфікацію Ingress без будь-яких правил маршрутизації?
weight: 40
---

Прості специфікації ingress, що включають хост, TLS і точні відповідності шляхів, будуть працювати без потреби в правилах маршрутизації. Однак зверніть увагу, що шлях, використаний у ресурсі ingress, не повинен містити символи `.`.

Наприклад, наступний ресурс ingress відповідає запитам для хосту example.com з URL /helloworld.

{{< text bash >}}
$ kubectl create -f - <<EOF
apiVersion: networking.k8s.io/v1
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
        pathType: Prefix
        backend:
          service:
            name: myservice
            port:
              number: 8000
EOF
{{< /text >}}

Однак наступні правила не працюватимуть, оскільки вони використовують регулярні вирази в шляху та анотації `ingress.kubernetes.io`:

{{< text bash >}}
$ kubectl create -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: this-will-not-work
  annotations:
    kubernetes.io/ingress.class: istio
    # Анотації Ingress, інші, ніж клас Ingress, не будуть враховані
    ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /hello(.*?)world/
        pathType: Prefix
        backend:
          service:
            name: myservice
            port:
              number: 8000
EOF
{{< /text >}}
