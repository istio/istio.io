---
title: Proxy de DNS
description: Cómo configurar el proxy de DNS.
weight: 60
keywords: [traffic-management,dns,virtual-machine]
owner: istio/wg-networking-maintainers
test: yes
---

Además de capturar el tráfico de las aplicaciones, Istio también puede capturar las solicitudes DNS para mejorar el rendimiento y la usabilidad de tu mesh.
Con el proxy de DNS, todas las solicitudes DNS de una aplicación se redirigen al proxy sidecar o ztunnel, que guarda un mapeo local de nombres de dominio a direcciones IP. Si el proxy puede atender la solicitud, devuelve directamente una respuesta a la aplicación y evita un viaje de ida y vuelta al servidor DNS upstream. Si no, la solicitud se reenvía upstream según la configuración DNS estándar de `/etc/resolv.conf`.

Aunque Kubernetes ofrece resolución DNS para los `Service`s de Kubernetes sin configuración adicional, no reconoce los `ServiceEntry`s personalizados. Con esta funcionalidad, las direcciones de los `ServiceEntry` se pueden resolver sin necesidad de configurar un servidor DNS personalizado. Para los `Service`s de Kubernetes, la respuesta DNS es la misma, pero se reduce la carga sobre `kube-dns` y mejora el rendimiento.

Esta funcionalidad también está disponible para servicios que se ejecutan fuera de Kubernetes. Esto significa que todos los servicios internos se pueden resolver sin recurrir a soluciones engorrosas para exponer las entradas DNS de Kubernetes fuera del clúster.

## Primeros pasos {#getting-started}

Por lo general, Istio enruta el tráfico según los encabezados HTTP. Si no es posible enrutar según un encabezado HTTP (en modo ambient, o con tráfico TCP en modo sidecar), puedes habilitar el proxy de DNS.

En modo ambient, ztunnel solo ve el tráfico en la capa 4 y no tiene acceso a los encabezados HTTP. Por eso, el proxy de DNS es necesario para resolver las direcciones de los `ServiceEntry`, especialmente cuando se [envía tráfico de salida a waypoints](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient#scenario-ztunnel-is-not-sending-egress-traffic-to-waypoints).

### Modo ambient {#ambient-mode}

El proxy de DNS está habilitado por defecto en modo ambient a partir de Istio 1.25.

En versiones anteriores a la 1.25, puedes habilitar la captura de DNS configurando `values.cni.ambient.dnsCapture=true` y `values.pilot.env.PILOT_ENABLE_IP_AUTOALLOCATE=true` durante la instalación.

Los pods pueden excluirse individualmente de la captura de DNS global del modo ambient con la anotación `ambient.istio.io/dns-capture=false`.

### Modo sidecar {#sidecar-mode}

Por ahora, esta funcionalidad no está habilitada por defecto. Para habilitarla, instala Istio con la siguiente configuración:

{{< text bash >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
EOF
{{< /text >}}

También se puede habilitar por pod con la [anotación `proxy.istio.io/config`](/es/docs/reference/config/annotations/):

{{< text syntax=yaml snip_id=none >}}
kind: Deployment
metadata:
  name: curl
spec:
...
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          proxyMetadata:
            ISTIO_META_DNS_CAPTURE: "true"
...
{{< /text >}}

{{< tip >}}
Al desplegar en una VM con [`istioctl workload entry configure`](/es/docs/setup/install/virtual-machine/), el proxy de DNS básico se habilita por defecto.
{{< /tip >}}

## Captura de DNS en acción {#dns-capture-in-action}

Para probar la captura de DNS, primero configura un `ServiceEntry` para algún servicio externo:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-address
spec:
  addresses:
  - 198.51.100.1
  hosts:
  - address.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
EOF
{{< /text >}}

Despliega una aplicación cliente que inicie la solicitud DNS:

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled --overwrite
$ kubectl apply -f @samples/curl/curl.yaml@
{{< /text >}}

Sin la captura de DNS, lo más probable es que una solicitud a `address.internal` no se pueda resolver. Una vez habilitada, deberías recibir una respuesta basada en la `address` configurada:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -sS -v address.internal
*   Trying 198.51.100.1:80...
{{< /text >}}

## Asignación automática de direcciones {#address-auto-allocation}

En el ejemplo anterior, tenías una dirección IP predefinida para el servicio al que enviaste la solicitud. Sin embargo, es habitual acceder a servicios externos que no tienen direcciones estables y dependen de DNS. En ese caso, el proxy de DNS no tiene suficiente información para devolver una respuesta y debe reenviar las solicitudes DNS upstream.

Esto es especialmente problemático con el tráfico TCP. A diferencia de las solicitudes HTTP, que se enrutan según los encabezados `Host`, TCP transporta mucha menos información: solo puedes enrutar según la IP y el número de puerto de destino. Como no tienes una IP estable para el backend, tampoco puedes enrutar según ella, y solo queda el número de puerto, lo que provoca conflictos cuando varios `ServiceEntry`s para servicios TCP comparten el mismo puerto. Consulta
[la siguiente sección](#external-tcp-services-without-vips) para más detalles.

Para resolver estos problemas, el proxy de DNS también permite asignar direcciones automáticamente a los `ServiceEntry`s que no definen una de forma explícita. La respuesta DNS incluye una dirección distinta y asignada automáticamente para cada `ServiceEntry`. Luego, el proxy se configura para hacer coincidir las solicitudes con esa dirección IP y reenviarlas al `ServiceEntry` correspondiente. Istio asigna automáticamente VIPs no enrutables (de la subred de clase E) a esos servicios, siempre que no usen un host comodín. El agente de Istio en el sidecar usa las VIPs como respuestas a las consultas DNS de la aplicación. Así, Envoy puede distinguir claramente el tráfico destinado a cada servicio TCP externo y reenviarlo al destino correcto.

{{< warning >}}
Como esta funcionalidad modifica las respuestas DNS, puede que no sea compatible con todas las aplicaciones.
{{< /warning >}}

Para probarlo, configura otro `ServiceEntry`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-auto
spec:
  hosts:
  - auto.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Ahora, envía una solicitud:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -sS -v auto.internal
*   Trying 240.240.0.1:80...
{{< /text >}}

Como puedes ver, la solicitud se envía a una dirección asignada automáticamente, `240.240.0.1`. Estas direcciones se toman del rango de direcciones IP reservado `240.240.0.0/16` para evitar conflictos con servicios reales.

Los usuarios también pueden configurar esto de forma más granular agregando la etiqueta `networking.istio.io/enable-autoallocate-ip="true/false"` a su `ServiceEntry`. Esta etiqueta indica si a un `ServiceEntry` que no define `spec.addresses` se le debe asignar automáticamente una dirección IP.

Para probarlo, actualiza el `ServiceEntry` existente con la etiqueta de exclusión:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-auto
  labels:
    networking.istio.io/enable-autoallocate-ip: "false"
spec:
  hosts:
  - auto.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Ahora, envía una solicitud y verifica que ya no se realiza la asignación automática:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -sS -v auto.internal
* Could not resolve host: auto.internal
* Store negative name resolve for auto.internal:80
* shutting down connection #0
{{< /text >}}

## Servicios TCP externos sin VIPs {#external-tcp-services-without-vips}

Por defecto, Istio tiene una limitación al enrutar tráfico TCP externo, porque no puede distinguir entre varios servicios TCP en el mismo puerto. Esta limitación es especialmente evidente al usar bases de datos de terceros, como AWS Relational Database Service, o cualquier base de datos configurada con redundancia geográfica. Por defecto, no se pueden gestionar por separado servicios TCP externos similares pero distintos. Para que el sidecar distinga el tráfico entre dos servicios TCP diferentes que están fuera de la mesh, los servicios deben estar en puertos distintos o tener VIPs globalmente únicas.

Por ejemplo, si tienes dos servicios de base de datos externos, `mysql-instance1` y `mysql-instance2`, y creas service entries para ambos, los sidecars de los clientes seguirán teniendo un único listener en `0.0.0.0:{port}` que busca la dirección IP solo de `mysql-instance1` en servidores DNS públicos y le reenvía el tráfico. No puede enrutar tráfico a `mysql-instance2` porque no tiene forma de distinguir si el tráfico que llega a `0.0.0.0:{port}` está destinado a `mysql-instance1` o a `mysql-instance2`.

El siguiente ejemplo muestra cómo usar el proxy de DNS para resolver este problema.
Se asigna una dirección IP virtual a cada service entry para que los sidecars de los clientes puedan distinguir claramente el tráfico destinado a cada servicio TCP externo.

1.  Actualiza la configuración de Istio indicada en la sección [Primeros pasos](#getting-started) para configurar también `discoverySelectors` que restrinjan la mesh a los namespaces que tienen `istio-injection` habilitado. Esto nos permite usar cualquier otro namespace del clúster para ejecutar servicios TCP fuera de la mesh.

    {{< text bash >}}
    $ cat <<EOF | istioctl install -y -f -
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          proxyMetadata:
            # Enable basic DNS proxying
            ISTIO_META_DNS_CAPTURE: "true"
        # discoverySelectors configuration below is just used for simulating the external service TCP scenario,
        # so that we do not have to use an external site for testing.
        discoverySelectors:
        - matchLabels:
            istio-injection: enabled
    EOF
    {{< /text >}}

1.  Despliega la primera aplicación TCP externa de ejemplo:

    {{< text bash >}}
    $ kubectl create ns external-1
    $ kubectl -n external-1 apply -f samples/tcp-echo/tcp-echo.yaml
    {{< /text >}}

1.  Despliega la segunda aplicación TCP externa de ejemplo:

    {{< text bash >}}
    $ kubectl create ns external-2
    $ kubectl -n external-2 apply -f samples/tcp-echo/tcp-echo.yaml
    {{< /text >}}

1.  Configura `ServiceEntry` para acceder a los servicios externos:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: external-svc-1
    spec:
      hosts:
      - tcp-echo.external-1.svc.cluster.local
      ports:
      - name: external-svc-1
        number: 9000
        protocol: TCP
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: external-svc-2
    spec:
      hosts:
      - tcp-echo.external-2.svc.cluster.local
      ports:
      - name: external-svc-2
        number: 9000
        protocol: TCP
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verifica que los listeners se configuran por separado para cada servicio en el lado del cliente:

    {{< text bash >}}
    $ istioctl pc listener deploy/curl | grep tcp-echo | awk '{printf "ADDRESS=%s, DESTINATION=%s %s\n", $1, $4, $5}'
    ADDRESS=240.240.105.94, DESTINATION=Cluster: outbound|9000||tcp-echo.external-2.svc.cluster.local
    ADDRESS=240.240.69.138, DESTINATION=Cluster: outbound|9000||tcp-echo.external-1.svc.cluster.local
    {{< /text >}}

## Limpieza {#cleanup}

{{< text bash >}}
$ kubectl -n external-1 delete -f @samples/tcp-echo/tcp-echo.yaml@
$ kubectl -n external-2 delete -f @samples/tcp-echo/tcp-echo.yaml@
$ kubectl delete -f @samples/curl/curl.yaml@
$ istioctl uninstall --purge -y
$ kubectl delete ns istio-system external-1 external-2
$ kubectl label namespace default istio-injection-
{{< /text >}}
