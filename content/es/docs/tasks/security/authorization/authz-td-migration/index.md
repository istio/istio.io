---
title: Migración de trust domain
description: Muestra cómo migrar de un trust domain a otro sin cambiar la política de autorización.
weight: 60
keywords: [security,access-control,rbac,authorization,trust domain, migration]
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo migrar de un trust domain a otro sin cambiar la política de autorización.

En Istio 1.4, introducimos una feature alfa para soportar la {{< gloss >}}trust domain migration{{</ gloss >}} para la política de autorización. Esto significa que si una
mesh de Istio necesita cambiar su {{< gloss >}}trust domain{{</ gloss >}}, la política de autorización no necesita ser cambiada manualmente.
En Istio, si un {{< gloss >}}workload{{</ gloss >}} se está ejecutando en el namespace `foo` con la cuenta de service `bar`, y el trust domain del sistema es `my-td`,
la identidad de dicho workload es `spiffe://my-td/ns/foo/sa/bar`. Por defecto, el trust domain de la mesh de Istio es `cluster.local`,
a menos que lo especifique durante la instalación.

## Antes de empezar

Antes de comenzar esta tarea, haga lo siguiente:

1. Lea los [conceptos de autorización de Istio](/es/docs/concepts/security/#authorization).

1. Instale Istio con un trust domain personalizado y mTLS habilitado.

    {{< text bash >}}
    $ istioctl install --set profile=demo --set meshConfig.trustDomain=old-td
    {{< /text >}}

1. Despliegue la muestra [httpbin]({{< github_tree >}}/samples/httpbin) en el namespace `default`
 y la muestra [curl]({{< github_tree >}}/samples/curl) en los namespaces `default` y `curl-allow`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    $ kubectl apply -f @samples/curl/curl.yaml@
    $ kubectl create namespace curl-allow
    $ kubectl label namespace curl-allow istio-injection=enabled
    $ kubectl apply -f @samples/curl/curl.yaml@ -n curl-allow
    {{< /text >}}

1. Aplique la política de autorización a continuación para denegar todas las solicitudes a `httpbin` excepto las de `curl` en el namespace `curl-allow`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: service-httpbin.default.svc.cluster.local
      namespace: default
    spec:
      rules:
      - from:
        - source:
            principals:
            - old-td/ns/curl-allow/sa/curl
        to:
        - operation:
            methods:
            - GET
      selector:
        matchLabels:
          app: httpbin
    ---
    EOF
    {{< /text >}}

    Tenga en cuenta que la política de autorización puede tardar decenas de segundos en propagarse a los sidecars.

1. Verifique que las solicitudes a `httpbin` desde:

    * `curl` en el namespace `default` son denegadas.

        {{< text bash >}}
        $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{\n}"
        403
        {{< /text >}}

    * `curl` en el namespace `curl-allow` son permitidas.

        {{< text bash >}}
        $ kubectl exec "$(kubectl -n curl-allow get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -n curl-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{\n}"
        200
        {{< /text >}}

## Migrar trust domain sin alias de trust domain

1. Instale Istio con un nuevo trust domain.

    {{< text bash >}}
    $ istioctl install --set profile=demo --set meshConfig.trustDomain=new-td
    {{< /text >}}

1. Vuelva a desplegar istiod para que recoja los cambios del trust domain.

    {{< text bash >}}
    $ kubectl rollout restart deployment -n istio-system istiod
    {{< /text >}}

    la mesh de Istio ahora se está ejecutando con un nuevo trust domain, `new-td`.

1. Vuelva a desplegar las applications `httpbin` y `curl` para que recojan los cambios del nuevo control plane de Istio.

    {{< text bash >}}
    $ kubectl delete pod --all
    {{< /text >}}

    {{< text bash >}}
    $ kubectl delete pod --all -n curl-allow
    {{< /text >}}

1. Verifique que las solicitudes a `httpbin` desde `curl` en el namespace `default` y en el namespace `curl-allow` son denegadas.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{\n}"
    403
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec "$(kubectl -n curl-allow get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -n curl-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{\n}"
    403
    {{< /text >}}

    Esto se debe a que especificamos una política de autorización que deniega todas las solicitudes a `httpbin`, excepto las de
    la identidad `old-td/ns/curl-allow/sa/curl`, que es la antigua identidad de la application `curl` en el namespace `curl-allow`.
    Cuando migramos a un nuevo trust domain, es decir, `new-td`, la identidad de esta application `curl` es ahora `new-td/ns/curl-allow/sa/curl`,
    que no es lo mismo que `old-td/ns/curl-allow/sa/curl`. Por lo tanto, las solicitudes de la application `curl` en el namespace `curl-allow`
    a `httpbin` que antes estaban permitidas ahora están siendo denegadas. Antes de Istio 1.4, la única forma de hacer que esto funcionara era cambiar la política de autorización
    manualmente. En Istio 1.4, introducimos una forma sencilla, como se muestra a continuación.

## Migrar trust domain con alias de trust domain

1. Instale Istio con un nuevo trust domain y alias de trust domain.

    {{< text bash >}}
    $ cat <<EOF > ./td-installation.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        trustDomain: new-td
        trustDomainAliases:
          - old-td
    EOF
    $ istioctl install --set profile=demo -f td-installation.yaml -y
    {{< /text >}}

1. Sin cambiar la política de autorización, verifique que las solicitudes a `httpbin` desde:

    * `curl` en el namespace `default` son denegadas.

        {{< text bash >}}
        $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{\n}"
        403
        {{< /text >}}

    * `curl` en el namespace `curl-allow` son permitidas.

        {{< text bash >}}
        $ kubectl exec "$(kubectl -n curl-allow get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -n curl-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{\n}"
        200
        {{< /text >}}

## Mejores prácticas

A partir de Istio 1.4, al escribir la política de autorización, debe considerar usar el valor `cluster.local` como la
parte del trust domain en la política. Por ejemplo, en lugar de `old-td/ns/curl-allow/sa/curl`, debería ser `cluster.local/ns/curl-allow/sa/curl`.
Tenga en cuenta que en este caso, `cluster.local` no es el trust domain de la mesh de Istio (el trust domain sigue siendo `old-td`). Sin embargo,
en la política de autorización, `cluster.local` es un puntero que apunta al trust domain actual, es decir, `old-td` (y más tarde `new-td`), así como a sus alias.
Al usar `cluster.local` en la política de autorización, cuando migre a un nuevo trust domain, Istio detectará esto y tratará el nuevo trust domain
como el antiguo trust domain sin que tenga que incluir los alias.

## Limpieza

{{< text bash >}}
$ kubectl delete authorizationpolicy service-httpbin.default.svc.cluster.local
$ kubectl delete deploy httpbin; kubectl delete service httpbin; kubectl delete serviceaccount httpbin
$ kubectl delete deploy curl; kubectl delete service curl; kubectl delete serviceaccount curl
$ istioctl uninstall --purge -y
$ kubectl delete namespace curl-allow istio-system
$ rm ./td-installation.yaml
{{< /text >}}
