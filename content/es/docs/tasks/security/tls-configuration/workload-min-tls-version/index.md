---
title: Configuración de la Versión Mínima de TLS del Workload de Istio
description: Muestra cómo configurar la versión mínima de TLS para los workloads de Istio.
weight: 90
keywords: [security,TLS]
aliases:
- /docs/tasks/security/workload-min-tls-version/
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo configurar la versión mínima de TLS para los workloads de Istio.
La versión máxima de TLS para los workloads de Istio es 1.3.

## Configuración de la versión mínima de TLS para los workloads de Istio

* Instale Istio a través de `istioctl` con la versión mínima de TLS configurada.
  El recurso personalizado `IstioOperator` utilizado para configurar Istio en el comando `istioctl install`
  contiene un campo para la versión mínima de TLS para los workloads de Istio.
  El campo `minProtocolVersion` especifica la versión mínima de TLS para las conexiones TLS
  entre los workloads de Istio. En el siguiente ejemplo,
  la versión mínima de TLS para los workloads de Istio se configura en 1.3.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        meshMTLS:
          minProtocolVersion: TLSV1_3
    EOF
    $ istioctl install -f ./istio.yaml
    {{< /text >}}

## Verificar la configuración TLS de los workloads de Istio

Después de configurar la versión mínima de TLS de los workloads de Istio,
puede verificar que la versión mínima de TLS se configuró y funciona como se esperaba.

* Despliegue dos workloads: `httpbin` y `curl`. Despliegue estos en un solo namespace,
  por ejemplo `foo`. Ambos workloads se ejecutan con un proxy Envoy delante de cada uno.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    {{< /text >}}

* Verifique que `curl` se comunica correctamente con `httpbin` utilizando este comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{\nhttp_code}"
    200
    {{< /text >}}

{{< warning >}}
Si no ve la salida esperada, inténtelo de nuevo después de unos segundos.
El almacenamiento en caché y la propagación pueden causar un retraso.
{{< /warning >}}

En el ejemplo, la versión mínima de TLS se configuró en 1.3.
Para verificar que TLS 1.3 está permitido, puede ejecutar el siguiente comando:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_3 -connect httpbin.foo:8000 | grep "TLSv1.3"
{{< /text >}}

La salida de texto debería incluir:

{{< text plain >}}
TLSv1.3
{{< /text >}}

Para verificar que TLS 1.2 no está permitido, puede ejecutar el siguiente comando:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_2 -connect httpbin.foo:8000 | grep "Cipher is (NONE)"
{{< /text >}}

La salida de texto debería incluir:

{{< text plain >}}
Cipher is (NONE)
{{< /text >}}

## Limpieza

Elimine las applications de ejemplo `curl` y `httpbin` del namespace `foo`:

{{< text bash >}}
$ kubectl delete -f samples/httpbin/httpbin.yaml -n foo
$ kubectl delete -f samples/curl/curl.yaml -n foo
{{< /text >}}

Desinstale Istio del cluster:

{{< text bash >}}
$ istioctl uninstall --purge -y
{{< /text >}}

Para eliminar los namespaces `foo` e `istio-system`:

{{< text bash >}}
$ kubectl delete ns foo istio-system
{{< /text >}}
