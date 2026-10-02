---
title: Rendimiento multiclúster de Ambient
description: Resumen de rendimiento y escalabilidad multiclúster de Ambient.
weight: 30
keywords:
  - performance
  - scalability
  - scale
  - multicluster
owner: istio/wg-environments-maintainers
test: n/a
---

Los despliegues multiclúster con modo ambient te permiten ofrecer aplicaciones verdaderamente resilientes a nivel global y a gran escala con una sobrecarga mínima. Además de sus funciones normales, el control plane de Istio crea watches en todos los clústeres remotos para mantener un listado actualizado de qué servicios globales ofrece cada clúster. El data plane de Istio puede enrutar tráfico hacia estos servicios globales remotos, ya sea como parte de la distribución de tráfico normal, o específicamente cuando el servicio local no está disponible.

## Rendimiento del control plane

Como se documenta [aquí](/es/docs/ops/deployment/performance-and-scalability), el control plane de Istio generalmente escala como el producto de los cambios de despliegue, los cambios de configuración y el número de proxies conectados. El multiclúster ambient agrega dos nuevas dimensiones a la historia de escalabilidad del control plane: el número de clústeres remotos y el número de servicios remotos. Debido a que el control plane no programa proxies para los clústeres remotos (asumiendo una topología de despliegue multiprimaria), agregar 10 servicios remotos a la mesh tiene un impacto sustancialmente menor en el rendimiento del control plane que agregar 10 servicios locales.

Nuestra prueba de carga del control plane multiclúster creó 300 servicios con 4000 endpoints en cada uno de 10 clústeres, y agregó estos clústeres a la mesh de uno en uno. El impacto aproximado en el control plane de agregar un clúster remoto a esta escala fue de **1% de un núcleo de CPU, y 180 MB de memoria**. A esta escala, debería ser seguro escalar bien más allá de 10 clústeres en una mesh con un control plane correctamente dimensionado. Un aspecto a tener en cuenta es que, para la escalabilidad multiclúster, escalar horizontalmente el control plane no ayudará, ya que cada instancia del control plane mantiene una caché completa de los servicios remotos. En su lugar, recomendamos modificar las solicitudes y límites de recursos del control plane para escalarlo verticalmente y satisfacer las necesidades de tu mesh multiclúster.

## Rendimiento del data plane

Cuando el tráfico se enruta hacia un clúster remoto, el data plane de origen establece un túnel cifrado hacia el gateway este/oeste del clúster de destino. Luego establece un segundo túnel cifrado dentro del primero, que termina en el data plane de destino. Este uso de túneles interno y externo permite que el data plane se comunique de forma segura con el clúster remoto sin conocer los detalles de qué IPs de pods representan qué servicios.

Sin embargo, esta doble encriptación sí conlleva cierta sobrecarga. La prueba de carga del data plane mide la latencia de respuesta del tráfico entre pods en el mismo clúster, frente a aquellos en dos clústeres diferentes, para entender el impacto de la doble encriptación en la latencia. Además, la doble encriptación requiere dobles negociaciones (handshakes), lo que afecta de forma desproporcionada a la latencia de las conexiones nuevas hacia el clúster remoto. Como puedes ver a continuación, nuestras conexiones iniciales observaron un promedio de 2.2 milisegundos (346%) de latencia adicional, mientras que las solicitudes que usan conexiones existentes observaron un incremento de 0.13 milisegundos (72%). Aunque estos números parecen significativos, se espera que la mayoría del tráfico multiclúster cruce zonas de disponibilidad o regiones, y el incremento observado en la latencia de sobrecarga será mínimo en comparación con la latencia total de tránsito entre centros de datos.

{{< image link="./ambient-mc-dataplane-reconnect.png" caption="latencia de solicitud con reconexión" width="90%" >}}

{{< image link="./ambient-mc-dataplane-existing.png" caption="latencia de solicitud sin reconexión" width="90%" >}}
