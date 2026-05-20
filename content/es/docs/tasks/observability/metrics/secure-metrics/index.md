---
title: Asegurar el scraping de Prometheus para sidecar y gateway de Istio
description: Esta tarea muestra cómo hacer scraping seguro de métricas de workloads e gateways de Istio en modo sidecar usando Prometheus e Istio mutual TLS (mTLS).
weight: 50
keywords: [telemetry,metrics,prometheus,istio,mtls]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

Esta tarea demuestra cómo **hacer scraping seguro de métricas de sidecar y gateway de Istio** usando Prometheus sobre **Istio mTLS**. Por defecto, Prometheus hace scraping de métricas de workloads y gateways de Istio sobre HTTP. En esta tarea, configuras Istio y Prometheus para que las métricas se recopilen de forma segura sobre conexiones cifradas. Este documento se enfoca específicamente en la telemetría generada por Envoy e Istio expuesta por sidecars y gateways. No cubre métricas a nivel de aplicación emitidas por los propios workloads. Para la integración general de Prometheus con Istio, incluyendo métricas de aplicación, consulta la documentación de [integración con Prometheus](/docs/ops/integrations/prometheus/).

## Entender el scraping de métricas por defecto

Por defecto, Istio expone métricas en el endpoint `/stats/prometheus`:

* Las métricas de workloads se sirven desde el puerto de telemetría del sidecar (`15020`) o el puerto exclusivo de Envoy (`15090`).
* Las métricas de gateways se sirven desde el puerto de telemetría del pod del gateway.
* Estos endpoints **no están protegidos por mutual TLS**, y hacer scraping directamente sobre HTTPS no se recomienda.

Esta tarea reemplaza el scraping por defecto con una **configuración segura habilitada para mTLS**. Prometheus usará un puerto frontal seguro (`15091`) en lugar de acceder directamente a los puertos de telemetría.

## Antes de comenzar

* [Instala Istio](/docs/setup) en tu clúster usando el **perfil default**.

## Instalar Prometheus con scraping seguro

Para habilitar el scraping seguro de métricas, Prometheus requiere un sidecar de Istio para autenticarse con workloads y gateways sobre mTLS.

1. Habilita la inyección de sidecar para el namespace de Prometheus

    {{< text bash >}}
    $ kubectl create namespace prometheus
    $ kubectl label namespace monitoring istio-injection=enabled --overwrite
    {{< /text >}}

    Esto asegura que cualquier pod de Prometheus creado o reiniciado tenga automáticamente un sidecar `istio-proxy`.

    {{< tip >}}
    El sidecar de Istio inyectado en el pod de Prometheus se usa únicamente para aprovisionar un certificado de workload de Istio para autenticación mTLS. La intercepción de tráfico está explícitamente deshabilitada y Prometheus continúa operando como un workload estándar de Kubernetes. Como alternativa, Istio puede integrarse con [cert-manager](docs/ops/integrations/certmanager/) para aprovisionar certificados para Prometheus. En ese modelo, no se requiere un sidecar de Istio.
    {{< /tip >}}

1. Actualiza la plantilla del pod del Deployment de Prometheus

    Istio proporciona una instalación de ejemplo de Prometheus en `samples/addons/prometheus.yaml`. Modifica `samples/addons/prometheus.yaml` para anotar el deployment de Prometheus y habilitar la inyección de sidecar, montar los certificados de Istio y configurar el proxy:

    {{< text yaml >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: prometheus
      namespace: monitoring
    spec:
      template:
        metadata:
          annotations:
            sidecar.istio.io/inject: "true"
            sidecar.istio.io/userVolumeMount: |
              [{"name": "istio-certs", "mountPath": "/etc/istio-certs", "readOnly": true}]
            proxy.istio.io/config: |
              proxyMetadata:
                OUTPUT_CERTS: /etc/istio-certs
              proxyMetadata.INBOUND_CAPTURE_PORTS: ""
        spec:
          containers:
          - name: prometheus
            image: prom/prometheus:latest
          volumes:
          - name: istio-certs
            secret:
              secretName: istio.default
    {{< /text >}}

    **Notas:**

    * `OUTPUT_CERTS` apunta a donde el sidecar de Istio escribe los certificados para que Prometheus los use.
    * `INBOUND_CAPTURE_PORTS: ""` evita que el sidecar intercepte el tráfico de Prometheus.
    * `userVolumeMount` monta los certificados dentro de Prometheus.

1. Modifica la configuración del Job de scraping de Prometheus en `samples/addons/prometheus.yaml` para agregar un job adicional para hacer scraping de métricas seguras:

    {{< text yaml >}}
    - job_name: 'istio-secure-merged-metrics'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_istio_io_secure_port]
        action: keep
        regex: .+
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels:
        - __meta_kubernetes_pod_ip
        - __meta_kubernetes_pod_annotation_prometheus_istio_io_secure_port
        action: replace
        target_label: __address__
        regex: (.+);(.+)
        replacement: $1:$2
      scheme: https
      tls_config:
        ca_file: /etc/istio-certs/root-cert.pem
        cert_file: /etc/istio-certs/cert-chain.pem
        key_file: /etc/istio-certs/key.pem
        insecure_skip_verify: true
    {{< /text >}}

1. Verifica que el pod de Prometheus tiene un sidecar de Istio

    {{< text bash >}}
    $ kubectl get pod <prometheus-pod> -n monitoring -o jsonpath='{.spec.containers[*].name}'
    {{< /text >}}

    Deberías ver un contenedor `istio-proxy`.

## Métricas seguras para sidecars

Esta tarea usa `httpbin` como workload de ejemplo para generar tráfico y métricas.

1. Habilita la inyección de sidecar en el namespace default y despliega httpbin

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml
    {{< /text >}}

1. Anota el pod de httpbin para el scraping seguro de Prometheus

    Asegúrate de que Prometheus hace scraping de métricas de forma segura a través del puerto mTLS (`15091`):

    {{< text bash >}}
    $ kubectl annotate pod -n default \
      -l app=httpbin \
      prometheus.io/scrape="true" \
      prometheus.io/path="/stats/prometheus" \
      prometheus.istio.io/secure-port="15091" \
      --overwrite
    {{< /text >}}

    Estas anotaciones permiten que Prometheus descubra el pod de httpbin y haga scraping de métricas a través del listener seguro.

1. Crea un listener seguro en el puerto 15091

    Las métricas del workload pueden exponerse de forma segura usando un listener de sidecar en el puerto `15091`. Esto reenvía requests desde el listener seguro al puerto de telemetría del sidecar `15020`. Para métricas solo de Envoy, usa el puerto `15090`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Sidecar
    metadata:
      name: secure-metrics
      namespace: default
    spec:
      ingress:
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTP
        defaultEndpoint: 127.0.0.1:15020 # Cambia a 15090 para métricas solo de Envoy
    EOF
    {{< /text >}}

## Métricas seguras para gateways

Los gateways de Istio exponen métricas que Prometheus puede recopilar. Por defecto, estas métricas están en los puertos `15020` para telemetría combinada y `15090` para telemetría solo de Envoy, y no están protegidas por mTLS. Los siguientes pasos configuran el scraping seguro en el puerto 15091 usando mTLS de Istio.

1. Crea un `Gateway` con listener seguro en el puerto `15091`.

    Creamos un `Gateway` para exponer tanto el tráfico HTTP estándar como un puerto HTTPS dedicado y seguro para métricas. El servidor HTTPS usa el modo TLS `ISTIO_MUTUAL` para que solo los clientes con certificados emitidos por Istio (como el sidecar de Prometheus) puedan hacer scraping de métricas.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: httpbin-gateway
      namespace: default
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts: ["*"]
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTPS
        tls:
          mode: ISTIO_MUTUAL
        hosts: ["*"]
    EOF
    {{< /text >}}

1. Crea un `ServiceEntry` para el puerto de telemetría del `Gateway` (15020 o 15090)

    Prometheus no puede acceder directamente a los puertos internos del gateway a menos que estén expuestos en la mesh. Un `ServiceEntry` permite que Prometheus enrute requests dentro de la mesh a estos puertos. Puedes elegir 15020 para telemetría combinada o 15090 para telemetría solo de Envoy.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: gateway-admin
      namespace: istio-system
    spec:
      hosts: [gateway-admin.local]
      location: MESH_INTERNAL
      ports:
      - number: 15020  # Cambia a 15090 para métricas solo de Envoy
        name: http-metrics
        protocol: HTTP
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    EOF
    {{< /text >}}

1. Crea un `VirtualService` para enrutar las métricas

    El `VirtualService` mapea los requests del listener seguro (15091) al `ServiceEntry` que apunta al puerto de telemetría (15020 o 15090). Esto asegura que los requests de métricas enviados a `https://<gateway-ip>:15091/stats/prometheus` se enruten correctamente dentro de la mesh.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: gateway-metrics
      namespace: default
    spec:
      hosts: ["*"]
      gateways: [httpbin-gateway]
      http:
      - match:
        - uri:
            prefix: /stats/prometheus
        route:
        - destination:
            host: gateway-admin.local
            port:
              number: 15020  # Cambia a 15090 para métricas solo de Envoy
    EOF
    {{< /text >}}

1. Anota el pod del `Gateway`

    {{< text bash >}}
    $ kubectl annotate pod -n istio-system <ingress-pod> prometheus.istio.io/secure-port=15091 --overwrite
    {{< /text >}}

## Verificación

### Verificar el scraping seguro de métricas con Prometheus

Después de completar la configuración, verifica que Prometheus está haciendo scraping exitosamente de las métricas de los workloads y gateways de Istio sobre **mutual TLS**.

1. Abre el dashboard de Prometheus

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    Este comando abre el dashboard de Prometheus en tu navegador por defecto.

1. Verifica los targets de scraping

    1. En la interfaz de Prometheus, navega a **Status → Targets**.
    1. Localiza el job llamado `istio-secure-merged-metrics` que es lo que usamos al configurar el nuevo job de scraping de Prometheus.

    Verifica que los targets para el workload httpbin y el Istio Ingress Gateway están listados con endpoints similares a: `https://<pod-ip>:15091/stats/prometheus   UP`. Cada target debería reportar un estado de **UP**.

Esto confirma que Prometheus está haciendo scraping de métricas usando **HTTPS sobre Istio mTLS** a través del puerto frontal seguro (`15091`), en lugar de acceder directamente a los puertos de telemetría (`15020` o `15090`).
