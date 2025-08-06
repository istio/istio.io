---
title: Implementación de Istio
description: Implementación de Istio.
subtitle: Lea sobre las buenas prácticas que conducen a una puesta en marcha rápida y efectiva para el día 1, el día 2 y el día 1000.
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /deployment.html
doc_type: about
---

{{< centered_block >}}

Ha decidido que desea utilizar Istio. ¡Bienvenido al mundo de la service mesh! Felicidades, ahora forma parte de una gran comunidad.

Si aún no lo ha hecho, le recomendamos probar Istio en un entorno de prueba siguiendo nuestra [guía de introducción](/es/docs/setup/getting-started/). Esto le dará una idea sobre las características de **gestión del tráfico**, **seguridad** y **observabilidad** que ofrece.

## ¿Lo hace usted mismo o busca ayuda?

Istio es un software de código abierto que puede descargar e instalar por su cuenta. Instalar una service mesh en un cluster de Kubernetes es tan simple como ejecutar un comando:

{{< text bash >}}
$ istioctl install
{{< /text >}}

A medida que se lanzan nuevas versiones, puede probarlas e implementarlas gradualmente en sus clusteres.

Muchos proveedores de servicios gestionados para Kubernetes ofrecen una opción automática para instalar y administrar Istio. Consulte nuestra [página de distribuidores](/about/ecosystem/) para ver si su proveedor admite Istio.

Además, Istio es la base que impulsa muchos productos de gestión empresarial de la service mesh, con equipos de expertos dispuestos a ayudarle a integrarlo.

Hay una creciente comunidad de consultores nativos de la nube capaces de ayudarle en su camino con Istio. Si planea trabajar con un miembro de este ecosistema, le recomendamos que se involucre lo antes posible. Muchos de nuestros socios y distribuidores han estado colaborando con el proyecto durante mucho tiempo y serán fundamentales para guiarle adecuadamente.

## ¿Qué funcionalidades debería habilitar primero?

Existen muchas buenas razones para adoptar Istio: desde agregar seguridad a sus microservicios hasta mejorar la fiabilidad de sus aplicaciones. Sin importar su objetivo, las implementaciones más exitosas de Istio comienzan identificando un caso de uso específico y solucionándolo. Una vez que haya configurado la service mesh para abordar algún problema, podrá habilitar fácilmente otras funcionalidades, incrementando así la utilidad general de su despliegue.

## ¿Cómo mapear la service mesh con mi arquitectura?

Introduzca gradualmente sus servicios en la service mesh labeling un namespace a la vez. Por defecto, los servicios en múltiples namespaces pueden comunicarse entre sí, pero puede aumentar el aislamiento seleccionando cuáles exponer a otros namespaces. El uso de namespaces también mejora el rendimiento ya que las configuraciones están limitadas.

Istio es flexible para adaptarse a la configuración de su clúster de Kubernetes y a la arquitectura de red. Puede optar por ejecutar múltiples mesh con planos de control independientes o tener uno solo.

Mientras los pods puedan conectarse a la red, Istio funcionará; incluso puede configurar gateways de Istio para que actúen como un host bastión entre diferentes redes.

Lea sobre [la amplia gama de modelos de implementación](/es/docs/ops/deployment/deployment-models/) en nuestra documentación.

Ahora también es momento de pensar en qué integraciones desea utilizar: recomendamos [configurar Prometheus](/es/docs/ops/integrations/prometheus/#Configuration) para la monitorización del servicio, junto con una [federación jerárquica a un servidor externo](/es/docs/ops/best-practices/observability/). Si su pila de observabilidad es manejada por otro equipo, ahora es el momento de involucrarlos.

## Añadir servicios a la service mesh en el día 1

Su service mesh ya está configurada y lista para aceptar servicios. Para ello, simplemente etiquete sus namespaces en Kubernetes; cuando estos servicios se vuelvan a implementar, incluirán automáticamente el proxy Envoy configurado para comunicarse con el control plane de Istio.

### Configurar servicios

Muchos servicios funcionarán "listos para usar", pero al añadir un poco más de información a sus manifiestos de Kubernetes podrá hacer que Istio sea mucho más inteligente. Por ejemplo, establecer labels como `app` y `version` le ayudará a obtener métricas posteriormente.

Para puertos y protocolos comunes, Istio detectará el tipo de tráfico automáticamente; si no puede, recurrirá al modo TCP por defecto, pero puede [añadir anotaciones](/es/docs/ops/configuration/traffic-management/protocol-selection/) fácilmente al servicio con el tipo de tráfico deseado.

Lea más sobre [cómo habilitar aplicaciones para que las utilice Istio](/es/docs/ops/deployment/application-requirements/).

### Habilitar seguridad

Istio configurará los servicios en su mesh para usar mTLS cuando sea posible. Por defecto, Istio se ejecutará en modo "mTLS permisivo", lo que significa que los servicios aceptarán tanto tráfico cifrado como no cifrado; esto permite mantener la funcionalidad del tráfico entre servicios fuera de la mesh temporalmente. Una vez que todos sus servicios estén integrados en la mesh, podrá [cambiar la política de autenticación](/es/docs/tasks/security/authentication/mtls-migration/) para permitir solo tráfico seguro (TLS).

### Las dos API de Istio

Istio tiene API para propietarios de plataformas y propietarios de servicios. Dependiendo de su rol, solo necesitará considerar un subconjunto específico. Por ejemplo, los propietarios de la plataforma se encargarán de la instalación, la autenticación y la autorización; mientras que los recursos de gestión del tráfico serán manejados por los propietarios del servicio. [Aprenda sobre las API relevantes](/es/docs/reference/config/).

## Conectar servicios en máquinas virtuales

Istio no es solo para Kubernetes; también puede [añadir servicios en máquinas virtuales](/es/docs/setup/install/virtual-machine/) (VM o bare metal) a su malla, obteniendo todos los beneficios que Istio proporciona, como TLS mutuo, telemetría y gestión avanzada del tráfico.

## Monitorizar sus servicios

Explore el tráfico que fluye por su mesh usando [Kiali](/docs/ops/integrations/kiali/) o haga un seguimiento de las solicitudes con [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/) o [Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/).

Use los paneles predeterminados de [Grafana](/es/docs/ops/integrations/grafana/) para Istio y obtenga informes automáticos de señales doradas para los servicios que se ejecutan en un mesh.

## Consideraciones operativas y Día 2

Como propietario de la plataforma, usted es responsable de instalar y mantener la mesh actualizado con poco impacto en los equipos de servicios.

### Instalación

Con istioctl, puede instalar Istio fácilmente utilizando uno de los perfiles incorporados. A medida que personaliza su instalación para satisfacer sus requisitos, se recomienda definir su configuración utilizando el recurso personalizado IstioOperator (CR). Esto le brinda la opción de delegar completamente la gestión de la instalación a un operador de Istio, en lugar de hacerlo manualmente con istioctl. Utilice un CR de IstioOperator solo para el control plane y CR de IstioOperator adicionales para las gateways para una mayor flexibilidad en las actualizaciones.

### Actualizar de forma segura

Cuando se lanza una nueva versión, Istio permite tanto actualizaciones in-place como canary. Elegir entre ambos implica una compensación entre la simplicidad y el posible tiempo de inactividad. Para entornos de producción, se recomienda utilizar el [método de actualización canary](/es/docs/setup/upgrade/canary/). Después de verificar que las nuevas versiones del control plane y del data plane funcionan correctamente, puede actualizar sus gateways.

### Supervisar la mesh

Istio genera telemetría detallada de todas las comunicaciones de servicios dentro de un mesh. Estas métricas, trazas y registros de acceso son vitales para comprender cómo interactúan sus aplicaciones entre sí e identificar posibles cuellos de botella en el rendimiento. Utilice esta información para ayudarle a configurar interruptores de circuito, tiempos de espera y reintentos, y fortalecer sus aplicaciones.

Al igual que sus aplicaciones que se ejecutan en la mesh, los componentes del control plane de Istio también exportan métricas. Aproveche estas métricas y los paneles preconfigurados de Grafana para ajustar sus solicitudes de recursos, límites y escalado.

## Únase a la comunidad de Istio

Una vez que esté ejecutando Istio, se ha convertido en miembro de una gran comunidad global. Puede hacer preguntas en [nuestro foro de discusión](https://discuss.istio.io/), o [entrar a Slack](https://slack.istio.io/). Y si desea mejorar algo, o tiene una solicitud de función, puede ir directamente a [GitHub](https://github.com/istio/istio).

¡Feliz mallado!

{{< /centered_block >}}
