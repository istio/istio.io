---
title: El soporte multiclúster multi-red en modo ambient pasa a Beta
description: Istio 1.29 llega con el soporte multiclúster multi-red en modo ambient en fase Beta, con mejoras en telemetría, conectividad y fiabilidad.
date: 2026-02-18
attribution: Gustavo Meira (Microsoft), Mikhail Krinkin (Microsoft)
keywords: [ambient,multicluster]
---

Nuestro equipo de colaboradores ha estado muy activo durante la transición a 2026. Se realizó mucho trabajo para llevar el soporte multiclúster multi-red para el modo ambient a un estado listo para producción. Se realizaron mejoras en áreas que van desde las pruebas internas hasta las solicitudes más populares de multiclúster multi-red en ambient, con un gran enfoque en la telemetría.

## Brechas en la telemetría

Los beneficios de un sistema distribuido multiclúster no están exentos de compromisos. Cierta complejidad es inevitable a mayor escala, lo que hace que una buena telemetría sea aún más importante. El equipo de Istio entendimos ese punto y éramos conscientes de algunas brechas que necesitaban cubrirse. Afortunadamente, en la versión 1.29, la telemetría es ahora más robusta y completa cuando nuestro data plane ambient opera sobre clústeres y redes distribuidos.

Si has desplegado capacidades multiclúster en fase alfa en escenarios multi-red, puede que hayas notado que algunas etiquetas de origen o destino aparecían como "unknown".

Para contexto, en un clúster local (o clústeres que comparten la misma red), el waypoint y ztunnel son conscientes de todos los endpoints existentes y adquieren esa información a través de xDS. Las métricas confusas suelen darse en despliegues multi-red donde, dada toda la información que debe replicarse entre redes separadas, el descubrimiento de peers mediante xDS resulta poco práctico. Desafortunadamente, esto ocasiona que falte información sobre el peer cuando las solicitudes atraviesan límites de red para alcanzar un clúster de Istio diferente.

## Mejoras de telemetría

Para superar ese problema, Istio 1.29 ahora incluye mecanismos de descubrimiento mejorados en su data plane para intercambiar metadatos de peers entre endpoints y gateways ubicados en diferentes redes. El protocolo HBONE se ha enriquecido con cabeceras de baggage, lo que permite que el waypoint y ztunnel intercambien información de peers de forma transparente a través de los east-west gateways.

{{< image link="./peer-metadata-exchange-diagram.png" caption="Diagrama que muestra el intercambio de metadatos de peers entre diferentes redes" >}}

En el diagrama anterior, centrándonos en las métricas L7, mostramos cómo los metadatos del peer fluyen a través de las cabeceras de baggage entre distintos clústeres ubicados en diferentes redes.

1. El cliente en el Clúster A inicia una solicitud, y ztunnel comienza a establecer una conexión HBONE a través del Waypoint. Esto significa que ztunnel envía una solicitud CONNECT con una cabecera de baggage que contiene los metadatos del peer del downstream. Esos metadatos se almacenan en el waypoint.
1. La cabecera de baggage con los metadatos se elimina y la solicitud se enruta normalmente. En este caso va a un clúster diferente.
1. En el lado receptor, el Ztunnel en el Clúster B recibe la solicitud HBONE y responde con un estado de éxito, adjuntando una cabecera de baggage, ahora con los metadatos del peer upstream.
1. Los metadatos del peer upstream son invisibles para el east-west gateway. Y cuando la respuesta llega al waypoint, ya tiene toda la información necesaria para emitir métricas sobre las dos partes involucradas.

Ten en cuenta que esta funcionalidad está actualmente detrás de un feature flag. Si quieres probar estas mejoras de telemetría, deben activarse explícitamente con la opción `AMBIENT_ENABLE_BAGGAGE`.

## Otras mejoras y correcciones

Se realizaron algunas bienvenidas [mejoras](/news/releases/1.29.x/announcing-1.29/change-notes/#traffic-management) en materia de conectividad. Los ingress gateways y los waypoint proxies ahora pueden enrutar solicitudes directamente a clústeres remotos. Esto sienta las bases para una mayor resiliencia y habilita patrones de diseño más flexibles que brindan las ventajas que los usuarios de Istio esperan en despliegues multiclúster y multi-red.

Y, por supuesto, también hemos añadido algunas correcciones menores que hacen que el soporte multiclúster multi-red sea más estable y robusto. Hemos actualizado la documentación de multiclúster para reflejar algunos de estos cambios, incluyendo la adición de una [guía](/docs/ambient/install/multicluster/observability) sobre cómo configurar Kiali para un despliegue ambient multi-red.

## Limitaciones y próximos pasos

Dicho esto, reconocemos que aún quedan algunas brechas sin cubrir completamente. La mayor parte del trabajo aquí se orientó al soporte multi-red. Ten en cuenta que el soporte multiclúster en despliegues de red única sigue considerándose en fase alfa.

Además, el east-west gateway puede dar preferencia a un endpoint específico durante un cierto período de tiempo. Esto puede tener algún impacto en cómo se distribuye la carga de las solicitudes provenientes de una red diferente entre los endpoints. Este es un comportamiento que afecta tanto al modo de data plane ambient como al basado en sidecar, y tenemos planes para abordarlo en ambos casos.

Estamos trabajando con la fantástica comunidad de Istio para abordar estas limitaciones. Por ahora, estamos emocionados de lanzar esta beta y esperamos recibir tu retroalimentación. El futuro se ve brillante para el soporte multiclúster multi-red en Istio.

Si deseas probar el soporte multiclúster multi-red en modo ambient, sigue [esta guía](/docs/ambient/install/multicluster/multi-primary_multi-network/). Recuerda que esta función está en fase beta y no está lista para uso en producción. Damos la bienvenida a tus informes de errores, pensamientos, comentarios y casos de uso. Puedes contactarnos en [GitHub](https://github.com/istio/istio) o [Slack](https://istio.slack.com/).
