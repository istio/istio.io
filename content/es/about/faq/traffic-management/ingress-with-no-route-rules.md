---
title: ¿Puedo usar la especificación de Ingress estándar sin ninguna regla de ruta?
weight: 40
---

Las especificaciones de ingress simples, con coincidencias basadas en host, TLS y ruta exacta
funcionarán de fábrica sin necesidad de reglas de ruta
. Sin embargo, tenga en cuenta que la ruta utilizada en el recurso de ingress no debe
tener ningún carácter `.`.

Por ejemplo, el siguiente recurso de ingress coincide con las solicitudes para el
host example.com, con /helloworld como URL.

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

Sin embargo, las siguientes reglas no funcionarán porque usan expresiones
regulares en la ruta y anotaciones `ingress.kubernetes.io`:

{{< text bash >}}
$ kubectl create -f - <<EOF
apiVersion: networking.k8s.io/v1
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
        pathType: Prefix
        backend:
          service:
            name: myservice
            port:
              number: 8000
EOF
{{< /text >}}
