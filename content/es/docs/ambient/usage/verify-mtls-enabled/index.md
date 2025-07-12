---
title: Verificar que mTLS está habilitado
description: Comprende cómo verificar que mTLS está habilitado entre las cargas de trabajo en una malla ambient.
weight: 15
owner: istio/wg-networking-maintainers
test: no
---

Una vez que hayas agregado aplicaciones a una malla ambient, puedes validar fácilmente que mTLS está habilitado entre tus cargas de trabajo usando uno o más de los siguientes métodos:

## Validar mTLS usando las configuraciones de ztunnel de la carga de trabajo

Usando el conveniente comando `istioctl ztunnel-config workloads`, puedes ver si tu carga de trabajo está configurada para enviar y aceptar tráfico HBONE a través del valor de la columna `PROTOCOL`. Por ejemplo:

{{< text syntax=bash >}}
$ istioctl ztunnel-config workloads
NAMESPACE    POD NAME                                IP         NODE                     WAYPOINT PROTOCOL
default      details-v1-857849f66-ft8wx              10.42.0.5  k3d-k3s-default-agent-0  None     HBONE
default      kubernetes                              172.20.0.3                          None     TCP
default      productpage-v1-c5b7f7dbc-hlhpd          10.42.0.8  k3d-k3s-default-agent-0  None     HBONE
default      ratings-v1-68d5f5486b-b5sbj             10.42.0.6  k3d-k3s-default-agent-0  None     HBONE
default      reviews-v1-7dc5fc4b46-ndrq9             10.42.1.5  k3d-k3s-default-agent-1  None     HBONE
default      reviews-v2-6cf45d556b-4k4md             10.42.0.7  k3d-k3s-default-agent-0  None     HBONE
default      reviews-v3-86cb7d97f8-zxzl4             10.42.1.6  k3d-k3s-default-agent-1  None     HBONE
{{< /text >}}

Tener HBONE configurado en tu carga de trabajo no significa que tu carga de trabajo rechazará cualquier tráfico de texto plano. Si quieres que tu carga de trabajo rechace el tráfico de texto plano, crea una política `PeerAuthentication` con el modo mTLS establecido en `STRICT` para tu carga de trabajo.

## Validar mTLS desde las métricas

Si has [instalado Prometheus](/es/docs/ops/integrations/prometheus/#installation), puedes configurar el reenvío de puertos y abrir la interfaz de usuario de Prometheus usando el siguiente comando:

{{< text syntax=bash >}}
$ istioctl dashboard prometheus
{{< /text >}}

En Prometheus, puedes ver los valores de las métricas de TCP. Primero, selecciona Gráfico e ingresa una métrica como: `istio_tcp_connections_opened_total`, `istio_tcp_connections_closed_total`, `istio_tcp_received_bytes_total` o `istio_tcp_sent_bytes_total`. Por último, haz clic en Ejecutar. Los datos contendrán entradas como:

{{< text syntax=plain >}}
istio_tcp_connections_opened_total{
  app="ztunnel",
  connection_security_policy="mutual_tls",
  destination_principal="spiffe://cluster.local/ns/default/sa/bookinfo-details",
  destination_service="details.default.svc.cluster.local",
  reporter="source",
  request_protocol="tcp",
  response_flags="-",
  source_app="curl",
  source_principal="spiffe://cluster.local/ns/default/sa/curl",source_workload_namespace="default",
  ...}
{{< /text >}}

Valida que el valor de `connection_security_policy` esté establecido en `mutual_tls` junto con la información de identidad de origen y destino esperada.

## Validar mTLS desde los registros

También puedes ver el registro de ztunnel de origen o destino para confirmar que mTLS está habilitado, junto con las identidades de los pares. A continuación se muestra un ejemplo del registro de ztunnel de origen para una solicitud del servicio `curl` al servicio `details`:

{{< text syntax=plain >}}
2024-08-21T15:32:05.754291Z info access connection complete src.addr=10.42.0.9:33772 src.workload="curl-7656cf8794-6lsm4" src.namespace="default"
src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.42.0.5:15008 dst.hbone_addr=10.42.0.5:9080 dst.service="details.default.svc.cluster.local"
dst.workload="details-v1-857849f66-ft8wx" dst.namespace="default" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-details"
direction="outbound" bytes_sent=84 bytes_recv=358 duration="15ms"
{{< /text >}}

Valida que los valores de `src.identity` y `dst.identity` sean correctos. Son las identidades utilizadas para la comunicación mTLS entre las cargas de trabajo de origen y destino. Consulta la sección [verificación del tráfico de ztunnel a través de los registros](/es/docs/ambient/usage/troubleshoot-ztunnel/#verifying-ztunnel-traffic-through-logs) para obtener más detalles.

## Validar con el panel de control de Kiali

Si tienes Kiali y Prometheus instalados, puedes visualizar la comunicación de tu carga de trabajo en la malla ambient usando el panel de control de Kiali. Puedes ver si la conexión entre dos cargas de trabajo tiene el icono del candado para validar que mTLS está habilitado, junto con la información de identidad del par:

{{< image link="./kiali-mtls.png" caption="Panel de control de Kiali" >}}

Consulta el documento [Visualizar la aplicación y las métricas](/es/docs/ambient/getting-started/secure-and-visualize/#visualize-the-application-and-metrics) para obtener más detalles.

## Validar con `tcpdump`

Si tienes acceso a tus nodos de trabajo de Kubernetes, puedes ejecutar el comando `tcpdump` para capturar todo el tráfico en la interfaz de red, con el enfoque opcional en los puertos de la aplicación y el puerto HBONE. En este ejemplo, el puerto `9080` es el puerto del servicio `details` y `15008` es el puerto HBONE:

{{< text syntax=bash >}}
$ tcpdump -nAi eth0 port 9080 or port 15008
{{< /text >}}

Deberías ver el tráfico cifrado en la salida del comando `tcpdump`.

Si no tienes acceso a los nodos de trabajo, puedes usar la [imagen del contenedor netshoot](https://hub.docker.com/r/nicolaka/netshoot) para ejecutar fácilmente el comando:

{{< text syntax=bash >}}
$ POD=$(kubectl get pods -l app=details -o jsonpath="{.items[0].metadata.name}")
$ kubectl debug $POD -i --image=nicolaka/netshoot -- tcpdump -nAi eth0 port 9080 or port 15008
{{< /text >}}
