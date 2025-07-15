---
title: Proteger y visualizar la aplicación
description: Habilita el modo ambient y protege la comunicación entre aplicaciones.
weight: 3
owner: istio/wg-networking-maintainers
test: yes
---

Agregar aplicaciones a una malla ambient es tan simple como etiquetarel namespace donde reside la aplicación. Al agregar las aplicaciones a la malla, proteges automáticamente la comunicación entre ellas e Istio comienza a recopilar telemetría TCP. Y no, ¡no necesitas reiniciar ni volver a desplegar las aplicaciones!

## Agregar Bookinfo a la malla

Puedes habilitar que todos los pods en un namespaces determinado formen parte de una malla ambient simplemente etiquetandoel namespace:

{{< text bash >}}
$ kubectl label namespace default istio.io/data plane-mode=ambient
namespace/default labeled
{{< /text >}}

¡Felicidades! Has agregado correctamente todos los pods enel namespace predeterminado a la malla ambient. 🎉

Si abres la aplicación Bookinfo en tu navegador, verás la página del producto, como antes. La diferencia esta vez es que la comunicación entre los pods de la aplicación Bookinfo está cifrada mediante mTLS. Además, Istio está recopilando telemetría TCP para todo el tráfico entre los pods.

{{< tip >}}
Ahora tienes cifrado mTLS entre todos tus pods, ¡sin siquiera reiniciar o volver a desplegar ninguna de las aplicaciones!
{{< /tip >}}

## Visualizar la aplicación y las métricas

Usando el panel de control de Istio, Kiali, y el motor de métricas de Prometheus, puedes visualizar la aplicación Bookinfo. Despliégalos ambos:

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f @samples/addons/prometheus.yaml@
$ kubectl apply -f @samples/addons/kiali.yaml@
{{< /text >}}

Puedes acceder al panel de control de Kiali ejecutando el siguiente comando:

{{< text syntax=bash snip_id=none >}}
$ istioctl dashboard kiali
{{< /text >}}

Enviemos algo de tráfico a la aplicación Bookinfo, para que Kiali genere el gráfico de tráfico:

{{< text bash >}}
$ for i in $(seq 1 100); do curl -sSI -o /dev/null http://localhost:8080/productpage; done
{{< /text >}}

A continuación, haz clic en el Gráfico de tráfico y selecciona "Default" en el menú desplegable "Seleccionar namespaces". Deberías ver la aplicación Bookinfo:

{{< image link="./kiali-ambient-bookinfo.png" caption="Panel de control de Kiali" >}}

{{< tip >}}
Si no ves el gráfico de tráfico, intenta volver a enviar el tráfico a la aplicación Bookinfo y asegúrate de haber seleccionadoel namespace **default** en el menú desplegable **Namespace** en Kiali.

Para ver el estado de mTLS entre los servicios, haz clic en el menú desplegable **Display** y haz clic en **Security**.
{{</ tip >}}

Si haces clic en la línea que conecta dos servicios en el panel de control, puedes ver las métricas de tráfico de entrada y salida recopiladas por Istio.

{{< image link="./kiali-tcp-traffic.png" caption="Tráfico L4" >}}

Además de las métricas de TCP, Istio ha creado una identidad sólida para cada servicio: un ID de SPIFFE. Esta identidad se puede utilizar para crear políticas de autorización.

## Próximos pasos

Ahora que tienes identidades asignadas a los servicios, vamos a [aplicar políticas de autorización](/es/docs/ambient/getting-started/enforce-auth-policies/) para proteger el acceso a la aplicación.
