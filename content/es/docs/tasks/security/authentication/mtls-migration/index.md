---
title: Migración de mTLS
description: Muestra cómo migrar incrementalmente sus services de Istio a mTLS.
weight: 40
keywords: [security,authentication,migration]
aliases:
    - /docs/tasks/security/mtls-migration/
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo asegurar que sus workloads solo se comuniquen usando mTLS a medida que se migran a
Istio.

Istio configura automáticamente los sidecars de los workloads para usar [mTLS](/es/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) al llamar a otros workloads. Por defecto, Istio configura los workloads de destino usando el modo `PERMISSIVE`.
Cuando el modo `PERMISSIVE` está habilitado, un service puede aceptar tanto tráfico de texto plano como tráfico mTLS. Para permitir
solo tráfico mTLS, la configuración debe cambiarse al modo `STRICT`.

Puede usar el [dashboard de Grafana](/es/docs/tasks/observability/metrics/using-istio-dashboard/) para
verificar qué workloads todavía están enviando tráfico de texto plano a los workloads en modo `PERMISSIVE` y optar por bloquearlos
una vez que la migración esté hecha.

## Antes de empezar

<!-- TODO: update the link after other PRs are merged -->

* Comprenda la [política de autenticación](/es/docs/concepts/security/#authentication-policies) de Istio y los conceptos relacionados de [autenticación mTLS](/es/docs/concepts/security/#mutual-tls-authentication).

* Lea la [tarea de política de autenticación](/es/docs/tasks/security/authentication/authn-policy) para
  aprender a configurar la política de autenticación.

* Tenga un cluster de Kubernetes con Istio instalado, sin mTLS global habilitado (por ejemplo, use el perfil de configuración `default` como se describe en los [pasos de instalación](/es/docs/setup/getting-started)).

En esta tarea, puede probar el proceso de migración creando workloads de ejemplo y modificando
las políticas para aplicar mTLS STRICT entre los workloads.

## Configurar el cluster

* Cree dos namespaces, `foo` y `bar`, y despliegue [httpbin]({{< github_tree >}}/samples/httpbin) y [curl]({{< github_tree >}}/samples/curl) con sidecars en ambos:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n bar
    {{< /text >}}

* Cree otro namespace, `legacy`, y despliegue [curl]({{< github_tree >}}/samples/curl) sin sidecar:

    {{< text bash >}}
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/curl/curl.yaml@ -n legacy
    {{< /text >}}

* Verifique la configuración enviando solicitudes http (usando curl) desde los pods curl, en los namespaces `foo`, `bar` y `legacy`, a `httpbin.foo` y `httpbin.bar`.
    Todas las solicitudes deberían tener éxito con el código de retorno 200.

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
    curl.foo to httpbin.foo: 200
    curl.foo to httpbin.bar: 200
    curl.bar to httpbin.foo: 200
    curl.bar to httpbin.bar: 200
    curl.legacy to httpbin.foo: 200
    curl.legacy to httpbin.bar: 200
    {{< /text >}}

    {{< tip >}}
    Si alguno de los comandos curl falla, asegúrese de que no existan políticas de autenticación o reglas de destino
    que puedan interferir con las solicitudes al service httpbin.

    {{< text bash >}}
    $ kubectl get peerauthentication --all-namespaces
    No resources found
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces
    No resources found
    {{< /text >}}

    {{< /tip >}}

## Bloquear a mTLS por namespace

Después de migrar todos los clientes a Istio e inyectar el sidecar de Envoy, puede bloquear los workloads en el namespace `foo`
para que solo acepten tráfico mTLS.

{{< text bash >}}
$ kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Ahora, debería ver que la solicitud de `curl.legacy` a `httpbin.foo` falla.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
{{< /text >}}

Si instaló Istio con `values.global.proxy.privileged=true`, puede usar `tcpdump` para verificar
si el tráfico está cifrado o no.

{{< text bash >}}
$ kubectl exec -nfoo "$(kubectl get pod -nfoo -lapp=httpbin -ojsonpath={.items..metadata.name})" -c istio-proxy -- sudo tcpdump dst port 80  -A
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
{{< /text >}}

Verá texto plano y texto cifrado en la salida cuando se envíen solicitudes desde `curl.legacy` y `curl.foo`
respectivamente.

Si no puede migrar todos sus services a Istio (es decir, inyectar el sidecar de Envoy en todos ellos), deberá seguir utilizando el modo `PERMISSIVE`.
Sin embargo, cuando se configura con el modo `PERMISSIVE`, no se realizarán comprobaciones de autenticación o autorización para el tráfico de texto plano por defecto.
Le recomendamos que utilice la [Autorización de Istio](/es/docs/tasks/security/authorization/authz-http/) para configurar diferentes rutas con diferentes políticas de autorización.

## Bloquear mTLS para toda la mesh

Puede bloquear los workloads en todos los namespaces para que solo acepten tráfico mTLS colocando la política en el namespace del sistema de su instalación de Istio.

{{< text bash >}}
$ kubectl apply -n istio-system -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Ahora, tanto los namespaces `foo` como `bar` aplican solo tráfico mTLS, por lo que debería ver que las solicitudes de `curl.legacy`
fallan para ambos.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
{{< /text >}}

## Limpiar el ejemplo

1. Elimine la política de autenticación a nivel de malla.

    {{< text bash >}}
    $ kubectl delete peerauthentication -n foo default
    $ kubectl delete peerauthentication -n istio-system default
    {{< /text >}}

1. Elimine los namespaces de prueba.

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    Namespaces foo bar legacy deleted.
    {{< /text >}}
