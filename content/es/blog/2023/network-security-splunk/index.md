---
title: "Seguridad de red integral en Splunk"
description: "Seguridad desde la Capa 3 hasta la Capa 7 con Istio y más."
publishdate: 2023-04-03
attribution: "Bernard Van De Walle (Splunk), Mitch Connors (Aviatrix)"
keywords: [Istio,Security,Use Case]
---

Con docenas de herramientas disponibles para asegurar tu red, es fácil encontrar tutoriales y demostraciones que ilustran cómo estas herramientas individuales hacen que tu red sea más segura al agregar identidad, política y observabilidad a tu tráfico. Lo que a menudo es menos claro es cómo estas herramientas interoperan para proporcionar seguridad integral para tu red en producción. ¿Cuántas herramientas necesitas? ¿Cuándo es tu red lo suficientemente segura?

Esta publicación explorará las herramientas y prácticas aprovechadas por Splunk para asegurar su infraestructura de red de Kubernetes, comenzando con el diseño y conectividad de VPC y llegando hasta la seguridad basada en solicitudes HTTP. En el camino, veremos lo que se necesita para proporcionar seguridad de red integral para tu stack nativo de la nube, cómo interoperan estas herramientas y dónde algunas de ellas pueden mejorar. Splunk utiliza una variedad de herramientas para asegurar su red, incluyendo:

* Funcionalidad de AWS
* Kubernetes
* Istio
* Envoy
* Aviatrix

## Sobre el caso de uso de Splunk

Splunk es una empresa de tecnología que proporciona una plataforma para recopilar, analizar y visualizar datos generados por diversas fuentes. Se utiliza principalmente para buscar, monitorear y analizar big data generado por máquinas a través de una interfaz estilo web. Splunk Cloud es una iniciativa para mover la infraestructura interna de Splunk a una arquitectura nativa de la nube. Hoy Splunk Cloud consta de más de 35 clústeres completamente replicados en AWS y GCP en regiones de todo el mundo.

## Asegurando la Capa 3/4: AWS, Aviatrix y Kubernetes

En Splunk Cloud, utilizamos un patrón llamado "VPCs de molde de galleta" donde cada clúster se aprovisiona con su propio VPC, con subredes privadas idénticas para IPs de Pod y Nodo, una subred pública para entrada y salida hacia y desde la internet pública, y una subred interna para el tráfico entre clústeres. Esto mantiene completamente aislados los Pods y Nodos de clústeres separados, mientras permite que el tráfico fuera del clúster tenga reglas particulares aplicadas en las subredes públicas e internas. Además, este patrón evita la posibilidad de agotamiento de IP privadas RFC 1918 al aprovechar muchos clústeres.

Dentro de cada VPC, se configuran ACLs de red y Grupos de Seguridad para restringir la conectividad a lo absolutamente requerido. Como ejemplo, restringimos la conectividad pública a nuestros nodos de Ingress (que desplegarán gateways de ingreso Envoy). Además del tráfico ordinario este-oeste y norte-sur, también hay servicios compartidos en Splunk a los que cada clúster necesita acceder. Aviatrix se utiliza para proporcionar acceso a VPC superpuestos, mientras también aplica algunas reglas de seguridad de alto nivel (segmentación por dominio).

{{< image width="90%"
    link="CNCS 2023 - VPC Connectivity 3.png"
    caption="Arquitectura de seguridad de red de Splunk"
    >}}

La siguiente capa de seguridad en el stack de Splunk es Kubernetes mismo. Los Webhooks de validación se utilizan para prevenir el despliegue de objetos K8S que permitirían tráfico inseguro en el clúster (típicamente alrededor de NLBs y servicios). Splunk también se basa en `NetworkPolicies` para asegurar y restringir la conectividad de Pod a Pod.

## Asegurando la Capa 7: Istio

Splunk utiliza Istio para aplicar políticas en la capa de aplicación basadas en los detalles de cada solicitud. Istio también emite datos de telemetría (métricas, logs, trazas) que son útiles para validar la seguridad a nivel de solicitud.

Uno de los beneficios clave de la inyección de sidecars Envoy de Istio es que Istio puede proporcionar cifrado en tránsito para toda la malla sin requerir ninguna modificación a las aplicaciones. Las aplicaciones envían solicitudes HTTP de texto plano, pero el sidecar Envoy intercepta el tráfico e implementa cifrado TLS mutuo para proteger contra interceptación o modificación.

Istio gestiona los gateways de ingreso de Splunk, que reciben tráfico de NLBs públicos e internos. Los gateways son gestionados por el equipo de plataforma y se ejecutan en el namespace Istio Gateway, permitiendo a los usuarios conectarse a ellos, pero no modificarlos. El servicio Gateway también se aprovisiona con certificados para aplicar TLS por defecto, y los Webhooks de validación aseguran que los servicios solo puedan conectarse a gateways para sus propios nombres de host. Además, los gateways aplican autenticación de solicitudes en el ingreso, antes de que el tráfico pueda impactar los pods de aplicación.

Debido a que Istio y los objetos K8S relacionados son relativamente complejos de configurar, Splunk creó una capa de abstracción, que es un controlador que configura todo para el servicio, incluyendo servicios virtuales, reglas de destino, gateways, certificados y más. Configura DNS que va directamente al NLB correcto. Es una solución de un clic para el despliegue de red de extremo a extremo. Para casos de uso más complejos, los equipos de servicios aún pueden omitir la abstracción y configurar estas configuraciones directamente.

{{< image width="90%"
    link="Splunk Platform.png"
    caption="Plataforma de aplicaciones de Splunk"
    >}}

## Puntos problemáticos

Aunque la arquitectura de Splunk satisface muchas de nuestras necesidades, hay algunos puntos problemáticos que vale la pena discutir. Istio opera creando tantos Sidecars Envoy como pods de aplicación, lo cual es un uso ineficiente de recursos. Además, cuando una aplicación particular tiene necesidades únicas de su sidecar, como CPU o memoria adicional, puede ser difícil ajustar estas configuraciones sin ajustarlas para todos los sidecars en la malla. La inyección de Sidecar de Istio involucra mucha magia, usando un webhook mutante para agregar un contenedor sidecar a cada pod a medida que se crea, lo que significa que esos pods ya no coinciden con sus despliegues correspondientes. Además, la inyección solo puede ocurrir en el momento de creación del pod, lo que significa que cada vez que se actualiza una versión o parámetro del sidecar, todos los pods deben reiniciarse antes de obtener la nueva configuración. En general, esta magia complica la ejecución de un service mesh en producción y agrega una gran cantidad de incertidumbre operacional a tu aplicación.

El proyecto Istio es consciente de estas limitaciones y cree que se mejorarán sustancialmente con el nuevo modo Ambient para Istio. En este modo, las construcciones de Capa 4 como identidad y cifrado serán aplicadas por un Daemon ejecutándose en el nodo, pero no en el mismo pod que la aplicación. Las características de Capa 7 aún serán manejadas por Envoy, pero Envoy se ejecutará en un pod adyacente como parte de su propio despliegue, en lugar de depender de la magia de la inyección de sidecar. Los pods de aplicación no serán modificados de ninguna manera en modo ambient, lo que debería agregar una buena cantidad de previsibilidad a las operaciones de service mesh. Se espera que el modo ambient alcance calidad Alpha en Istio 1.18.

## Conclusión

Con todas estas capas de seguridad de red en Splunk Cloud, es útil dar un paso atrás y examinar la vida de una solicitud mientras atraviesa estas capas. Cuando un cliente envía una solicitud, primero se conecta al NLB, que será permitido o bloqueado por las `ACLs de VPC`. El NLB luego proxy la solicitud a uno de los nodos de ingreso, que termina TLS e inspecciona la solicitud en Capa 7, eligiendo permitir o bloquear la solicitud. El Gateway Envoy luego valida la solicitud usando `ExtAuthZ` para asegurar que esté correctamente autenticada y cumpla con las restricciones de cuota antes de permitirse en el clúster. A continuación, el Gateway Envoy proxy la solicitud upstream, y las políticas de red de Kubernetes entran en efecto nuevamente para asegurarse de que este proxy esté permitido. El sidecar upstream en la carga de trabajo inspecciona las solicitudes de Capa 7 y si está permitido, descifrará la solicitud y la enviará a la carga de trabajo en texto claro.

{{< image width="90%"
    link="security matrix.png"
    caption="Matriz de seguridad de red nativa de la nube"
    >}}

Asegurar el Stack de Red Nativo de la Nube de Splunk mientras se satisfacen las necesidades de escalabilidad de esta gran empresa requiere una planificación de seguridad cuidadosa en cada capa.

Aunque aplicar principios de identidad, observabilidad y política en cada capa del stack puede parecer redundante a primera vista, cada capa es capaz de compensar las deficiencias de las otras, de modo que juntas estas capas forman una barrera estrecha y efectiva contra el acceso no deseado.

Si estás interesado en profundizar en el Stack de Seguridad de Red de Splunk, puedes ver nuestra [presentación](https://youtu.be/OuRQnJKIEaM) de Cloud Native SecurityCon.
