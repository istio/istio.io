---
title: Acceso Remoto a los Addons de Telemetría
description: Esta tarea muestra cómo configurar el acceso externo al conjunto de addons de telemetría de Istio.
weight: 98
keywords: [telemetry,gateway,jaeger,zipkin,tracing,kiali,prometheus,addons]
aliases:
 - /docs/tasks/telemetry/gateways/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Esta tarea muestra cómo configurar Istio para exponer y acceder a los addons de telemetría fuera de
un cluster.

## Configuración del acceso remoto

El acceso remoto a los addons de telemetría se puede configurar de varias maneras. Esta tarea cubre
dos métodos de acceso básicos: seguro (a través de HTTPS) e inseguro (a través de HTTP). El método seguro es *muy
recomendado* para cualquier entorno de producción o sensible. El acceso inseguro es más sencillo de configurar, pero
no protegerá ninguna credencial o dato transmitido fuera de su cluster.

Para ambas opciones, primero siga estos pasos:

1. [Instale Istio](/es/docs/setup/install/istioctl) en su cluster.

    Para instalar adicionalmente los addons de telemetría, siga la documentación de [integraciones](/es/docs/ops/integrations/).

1. Configure el dominio para exponer los addons. En este ejemplo, expone cada addon en un subdominio, como `grafana.example.com`.

    * Si tiene un dominio existente que apunta a la dirección IP externa de `istio-ingressgateway` (por ejemplo, example.com):

    {{< text bash >}}
    $ export INGRESS_DOMAIN="example.com"
    {{< /text >}}

    * Si no tiene un dominio, puede usar [`nip.io`](https://nip.io/) que se resolverá automáticamente a la dirección IP proporcionada. Esto no se recomienda para uso en producción.

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
    {{< /text >}}

### Opción 1: Acceso seguro (HTTPS)

Se requiere un certificado de servidor para el acceso seguro. Siga estos pasos para instalar y configurar
certificados de servidor para un dominio que controle.

{{< warning >}}
Esta opción cubre solo la seguridad de la capa de transporte. También debe configurar los
addons de telemetría para requerir autenticación al exponerlos externamente.
{{< /warning >}}

Este ejemplo utiliza certificados autofirmados, que pueden no ser apropiados para usos de producción. Para estos casos, considere usar [cert-manager](/es/docs/ops/integrations/certmanager/) u otras herramientas para aprovisionar certificados. También puede visitar la tarea [Asegurar Gateways con HTTPS](/es/docs/tasks/traffic-management/ingress/secure-ingress/) para obtener información general sobre el uso de HTTPS en el gateway.

1. Configure los certificados. Este ejemplo utiliza `openssl` para autofirmar.

    {{< text bash >}}
    $ CERT_DIR=/tmp/certs
    $ mkdir -p ${CERT_DIR}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj "/O=example Inc./CN=*.${INGRESS_DOMAIN}" -keyout ${CERT_DIR}/ca.key -out ${CERT_DIR}/ca.crt
    $ openssl req -out ${CERT_DIR}/cert.csr -newkey rsa:2048 -nodes -keyout ${CERT_DIR}/tls.key -subj "/CN=*.${INGRESS_DOMAIN}/O=example organization"
    $ openssl x509 -req -sha256 -days 365 -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0 -in ${CERT_DIR}/cert.csr -out ${CERT_DIR}/tls.crt
    $ kubectl create -n istio-system secret tls telemetry-gw-cert --key=${CERT_DIR}/tls.key --cert=${CERT_DIR}/tls.crt
    {{< /text >}}

1. Aplique la configuración de red para los addons de telemetría.

    1. Aplique la siguiente configuración para exponer Grafana:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: grafana-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-grafana
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "grafana.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "grafana.${INGRESS_DOMAIN}"
          gateways:
          - grafana-gateway
          http:
          - route:
            - destination:
                host: grafana
                port:
                  number: 3000
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: grafana
          namespace: istio-system
        spec:
          host: grafana
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/grafana-gateway created
        virtualservice.networking.istio.io/grafana-vs created
        destinationrule.networking.istio.io/grafana created
        {{< /text >}}

    1. Aplique la siguiente configuración para exponer Kiali:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: kiali-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-kiali
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "kiali.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "kiali.${INGRESS_DOMAIN}"
          gateways:
          - kiali-gateway
          http:
          - route:
            - destination:
                host: kiali
                port:
                  number: 20001
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: kiali
          namespace: istio-system
        spec:
          host: kiali
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/kiali-gateway created
        virtualservice.networking.istio.io/kiali-vs created
        destinationrule.networking.istio.io/kiali created
        {{< /text >}}

    1. Aplique la siguiente configuración para exponer Prometheus:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: prometheus-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-prom
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "prometheus.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "prometheus.${INGRESS_DOMAIN}"
          gateways:
          - prometheus-gateway
          http:
          - route:
            - destination:
                host: prometheus
                port:
                  number: 9090
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: prometheus
          namespace: istio-system
        spec:
          host: prometheus
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/prometheus-gateway created
        virtualservice.networking.istio.io/prometheus-vs created
        destinationrule.networking.istio.io/prometheus created
        {{< /text >}}

    1. Aplique la siguiente configuración para exponer el service de trazado:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: tracing-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-tracing
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "tracing.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "tracing.${INGRESS_DOMAIN}"
          gateways:
          - tracing-gateway
          http:
          - route:
            - destination:
                host: tracing
                port:
                  number: 80
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: tracing
          namespace: istio-system
        spec:
          host: tracing
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/tracing-gateway created
        virtualservice.networking.istio.io/tracing-vs created
        destinationrule.networking.istio.io/tracing created
        {{< /text >}}

1. Visite los addons de telemetría a través de su navegador.

    {{< warning >}}
    Si usó certificados autofirmados, su navegador probablemente los marcará como inseguros.
    {{< /warning >}}

    * Kiali: `https://kiali.${INGRESS_DOMAIN}`
    * Prometheus: `https://prometheus.${INGRESS_DOMAIN}`
    * Grafana: `https://grafana.${INGRESS_DOMAIN}`
    * Tracing: `https://tracing.${INGRESS_DOMAIN}`

### Opción 2: Acceso inseguro (HTTP)

1. Aplique la configuración de red para los addons de telemetría.

    1. Aplique la siguiente configuración para exponer Grafana:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: grafana-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-grafana
              protocol: HTTP
            hosts:
            - "grafana.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "grafana.${INGRESS_DOMAIN}"
          gateways:
          - grafana-gateway
          http:
          - route:
            - destination:
                host: grafana
                port:
                  number: 3000
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: grafana
          namespace: istio-system
        spec:
          host: grafana
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/grafana-gateway created
        virtualservice.networking.istio.io/grafana-vs created
        destinationrule.networking.istio.io/grafana created
        {{< /text >}}

    1. Aplique la siguiente configuración para exponer Kiali:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: kiali-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-kiali
              protocol: HTTP
            hosts:
            - "kiali.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "kiali.${INGRESS_DOMAIN}"
          gateways:
          - kiali-gateway
          http:
          - route:
            - destination:
                host: kiali
                port:
                  number: 20001
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: kiali
          namespace: istio-system
        spec:
          host: kiali
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/kiali-gateway created
        virtualservice.networking.istio.io/kiali-vs created
        destinationrule.networking.istio.io/kiali created
        {{< /text >}}

    1. Aplique la siguiente configuración para exponer Prometheus:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: prometheus-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-prom
              protocol: HTTP
            hosts:
            - "prometheus.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "prometheus.${INGRESS_DOMAIN}"
          gateways:
          - prometheus-gateway
          http:
          - route:
            - destination:
                host: prometheus
                port:
                  number: 9090
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: prometheus
          namespace: istio-system
        spec:
          host: prometheus
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/prometheus-gateway created
        virtualservice.networking.istio.io/prometheus-vs created
        destinationrule.networking.istio.io/prometheus created
        {{< /text >}}

    1. Aplique la siguiente configuración para exponer el service de trazado:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: tracing-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-tracing
              protocol: HTTP
            hosts:
            - "tracing.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "tracing.${INGRESS_DOMAIN}"
          gateways:
          - tracing-gateway
          http:
          - route:
            - destination:
                host: tracing
                port:
                  number: 80
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: tracing
          namespace: istio-system
        spec:
          host: tracing
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/tracing-gateway created
        virtualservice.networking.istio.io/tracing-vs created
        destinationrule.networking.istio.io/tracing created
        {{< /text >}}

1. Visite los addons de telemetría a través de su navegador.

    * Kiali: `http://kiali.${INGRESS_DOMAIN}`
    * Prometheus: `http://prometheus.${INGRESS_DOMAIN}`
    * Grafana: `http://grafana.${INGRESS_DOMAIN}`
    * Tracing: `http://tracing.${INGRESS_DOMAIN}`

## Limpieza

* Elimine todos los Gateways relacionados:

    {{< text bash >}}
    $ kubectl -n istio-system delete gateway grafana-gateway kiali-gateway prometheus-gateway tracing-gateway
    gateway.networking.istio.io "grafana-gateway" deleted
    gateway.networking.istio.io "kiali-gateway" deleted
    gateway.networking.istio.io "prometheus-gateway" deleted
    gateway.networking.istio.io "tracing-gateway" deleted
    {{< /text >}}

* Elimine todos los VirtualServices relacionados:

    {{< text bash >}}
    $ kubectl -n istio-system delete virtualservice grafana-vs kiali-vs prometheus-vs tracing-vs
    virtualservice.networking.istio.io "grafana-vs" deleted
    virtualservice.networking.istio.io "kiali-vs" deleted
    virtualservice.networking.istio.io "prometheus-vs" deleted
    virtualservice.networking.istio.io "tracing-vs" deleted
    {{< /text >}}

* Elimine todas las DestinationRules relacionadas:

    {{< text bash >}}
    $ kubectl -n istio-system delete destinationrule grafana kiali prometheus tracing
    destinationrule.networking.istio.io "grafana" deleted
    destinationrule.networking.istio.io "kiali" deleted
    destinationrule.networking.istio.io "prometheus" deleted
    destinationrule.networking.istio.io "tracing" deleted
    {{< /text >}}
