---
title: Extender waypoints con plugins de WebAssembly
description: Describe cómo hacer que los módulos de WebAssembly remotos estén disponibles para el modo ambient.
weight: 55
keywords: [extensibility,Wasm,WebAssembly,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio proporciona la capacidad de [extender su funcionalidad usando WebAssembly (Wasm)](/es/docs/concepts/wasm/).
Una de las ventajas clave de la extensibilidad de Wasm es que las extensiones se pueden cargar dinámicamente en tiempo de ejecución. Este documento describe cómo extender el modo ambient dentro de Istio con características de Wasm. En el modo ambient, la configuración de Wasm debe aplicarse al proxy de waypoint desplegado en cada namespace.

## Antes de empezar

1. Configura Istio siguiendo las instrucciones de la [guía de introducción al modo ambient](/es/docs/ambient/getting-started).
1. Despliega la [aplicación de ejemplo Bookinfo](/es/docs/ambient/getting-started/deploy-sample-app).
1. [Agrega el namespace predeterminado a la malla ambient](/es/docs/ambient/getting-started/secure-and-visualize).
1. Despliega la aplicación de ejemplo [curl]({{< github_tree >}}/samples/curl) para usarla como fuente de prueba para enviar solicitudes.

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

## En una gateway

Con la API de Gateway de Kubernetes, Istio proporciona un punto de entrada centralizado para gestionar el tráfico hacia la service mesh. Configuraremos un WasmPlugin a nivel de gateway, asegurando que todo el tráfico que pase por la gateway esté sujeto a las reglas de autenticación extendidas.

### Configurar un plugin de WebAssembly para una gateway

En este ejemplo, agregarás un módulo de autenticación [Básica HTTP](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) a tu malla. Configurarás Istio para que extraiga el módulo de autenticación Básica de un registro de imágenes remoto y lo cargue. Se configurará para que se ejecute en las llamadas a `/productpage`. Estos pasos son similares a los de [Distribución de módulos de WebAssembly](/es/docs/tasks/extensibility/wasm-module-distribution/), con la diferencia del uso del campo `targetRefs` en lugar de los selectores de etiquetas.

Para configurar un filtro de WebAssembly con un módulo Wasm remoto, crea un recurso `WasmPlugin` que apunte a la `bookinfo-gateway`:

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

{{< text syntax=bash snip_id=apply_wasmplugin_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway # nombre de la gateway recuperado del paso anterior
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

Se inyectará un filtro HTTP en la gateway como un filtro de autenticación.
El agente de Istio interpretará la configuración de WasmPlugin, descargará los módulos Wasm remotos del registro de imágenes OCI a un archivo local e inyectará el filtro HTTP en la gateway haciendo referencia a ese archivo.

### Verificar el tráfico a través de la gateway

1. Probar `/productpage` sin credenciales:

    {{< text syntax=bash snip_id=test_gateway_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    401
    {{< /text >}}

1. Probar `/productpage` con las credenciales configuradas en el recurso WasmPlugin:

    {{< text syntax=bash snip_id=test_gateway_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    200
    {{< /text >}}

## En un waypoint, para todos los servicios en un namespace

Los proxies de waypoint juegan un papel crucial en el modo ambient de Istio, facilitando una comunicación segura y eficiente dentro de la service mesh. A continuación, exploraremos cómo aplicar la configuración de Wasm al waypoint, mejorando la funcionalidad del proxy de forma dinámica.

### Desplegar un proxy de waypoint

Sigue las [instrucciones de despliegue de waypoint](/es/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy) para desplegar un proxy de waypoint en el namespace de bookinfo.

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

Verificar que el tráfico llega al servicio:

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

### Configurar un plugin de WebAssembly para un waypoint

Para configurar un filtro de WebAssembly con un módulo Wasm remoto, crea un recurso `WasmPlugin` que apunte a la gateway `waypoint`:

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint # nombre de la gateway recuperado del paso anterior
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### Ver el plugin configurado

{{< text syntax=bash snip_id=get_wasmplugin >}}
$ kubectl get wasmplugin
NAME                     AGE
basic-auth-at-gateway    28m
basic-auth-at-waypoint   14m
{{< /text >}}

### Verificar el tráfico a través del proxy de waypoint

1. Probar `/productpage` interno sin credenciales:

    {{< text syntax=bash snip_id=test_waypoint_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
    401
    {{< /text >}}

1. Probar `/productpage` interno con credenciales:

    {{< text syntax=bash snip_id=test_waypoint_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

## En un waypoint, para un servicio específico

Para configurar un filtro de WebAssembly con un módulo Wasm remoto para un servicio específico, crea un recurso WasmPlugin que apunte directamente al servicio específico.

Crea un `WasmPlugin` que apunte al servicio `reviews` para que la extensión se aplique solo al servicio `reviews`. En esta configuración, el token de autenticación y el prefijo se adaptan específicamente para el servicio de revisiones, asegurando que solo las solicitudes dirigidas a él estén sujetas a este mecanismo de autenticación.

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-for-service
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/reviews"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "MXQtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### Verificar el tráfico que apunta al Servicio

1. Probar el `/productpage` interno con las credenciales configuradas en el proxy `waypoint` genérico:

    {{< text syntax=bash snip_id=test_waypoint_service_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

1. Probar el `/reviews` interno con las credenciales configuradas en el proxy `reviews-svc-waypoint` específico:

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic MXQtaW4zOmFkbWluMw==" http://reviews:9080/reviews/1
    200
    {{< /text >}}

1. Probar `/reviews` interno sin credenciales:

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://reviews:9080/reviews/1
    401
    {{< /text >}}

Al ejecutar el comando proporcionado sin credenciales, se verifica que el acceso al `/productpage` interno da como resultado una respuesta 401 no autorizada, lo que demuestra el comportamiento esperado de no poder acceder al recurso sin las credenciales de autenticación adecuadas.

## Limpieza

1. Eliminar la configuración de WasmPlugin:

    {{< text syntax=bash snip_id=remove_wasmplugin >}}
    $ kubectl delete wasmplugin basic-auth-at-gateway basic-auth-at-waypoint basic-auth-for-service
    {{< /text >}}

1. Sigue la [guía de desinstalación del modo ambient](/es/docs/ambient/getting-started/#uninstall) para eliminar Istio y las aplicaciones de prueba de ejemplo.
