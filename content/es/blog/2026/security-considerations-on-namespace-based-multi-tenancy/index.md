---
title: "Consideraciones de seguridad sobre los CRDs de Istio en entornos multi-tenancy basados en namespaces"
description: Abordando vulnerabilidades de tipo man-in-the-middle en configuraciones multi-tenant basadas en namespaces.
publishdate: 2026-03-21
attribution: "Lorin Lehawany - ERNW, Sven Nobis - ERNW"
keywords: [Istio,Security,Multi-Tenancy,MITM,Man-in-the-Middle]
---

El proyecto Istio quiere abordar un posible escenario de ataque de tipo Man-in-the-Middle (MITM) en el que un `VirtualService` puede redirigir o interceptar tráfico dentro de la service mesh. Esto afecta a clústeres multi-tenant basados en namespaces donde los inquilinos tienen permisos para desplegar recursos de Istio (`networking.istio.io/v1`).

Esta publicación destaca los riesgos de usar Istio en clústeres multi-tenant y explica cómo los usuarios pueden mitigar estos riesgos y operar Istio de forma segura en sus despliegues.

Ten en cuenta que los problemas incluso se extienden más allá del ámbito del clúster en un [despliegue _"single mesh con múltiples clústeres"_](/docs/ops/deployment/deployment-models/#multiple-clusters).

El comportamiento descrito en esta publicación aplica a Istio versión 1.29.0 y a todas las versiones desde la introducción de la opción mesh gateway en el recurso `VirtualService`.

## Contexto

### Multi-tenancy basado en namespaces

Los namespaces en Kubernetes proporcionan un mecanismo para organizar grupos de recursos dentro de un clúster. Los namespaces ofrecen una abstracción lógica que permite a equipos, aplicaciones o entornos compartir un mismo clúster mientras aíslan sus recursos mediante controles como Network Policies, RBAC, etc.

En esta publicación, nos enfocamos en ejecutar Istio en clústeres donde múltiples inquilinos comparten el mismo clúster y la misma service mesh, y pueden desplegar recursos de Istio (`networking.istio.io/v1`) en sus namespaces mientras confían en los límites de namespace para el aislamiento.

### Enrutamiento de tráfico en Istio

Istio proporciona capacidades de gestión de tráfico separando la lógica de la aplicación del comportamiento de enrutamiento de red.
Introduce recursos de configuración adicionales a través de CRDs que permiten a los operadores definir cómo debe enrutarse el tráfico entre servicios en la mesh.

Uno de los recursos centrales para este propósito es el `VirtualService`. Un `VirtualService` define un conjunto de reglas de enrutamiento que determinan cómo se manejan las solicitudes a los hosts especificados en `spec.hosts.[]`. Estas reglas pueden hacer coincidir solicitudes basándose en propiedades como headers HTTP, paths o puertos, y luego pueden dirigir el tráfico a uno o más servicios de destino.

Las decisiones de enrutamiento definidas en un `VirtualService` no se limitan a un solo workload o namespace. Dependiendo de cómo se configure el recurso, estas reglas pueden afectar el enrutamiento de tráfico en toda la mesh.

A diferencia de la más reciente [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/), estos CRDs fueron creados y efectivamente estabilizados antes de que el RBAC basado en namespaces llegara a Kubernetes. Por tanto, el multi-tenancy basado en namespaces que comparte la misma service mesh no formaba parte del modelo de amenazas en ese momento. Con la introducción de RBAC, surgieron estos entornos multi-tenant. Por ello, es importante destacar y abordar los riesgos de seguridad asociados a esas arquitecturas.

En la siguiente sección, demostramos esos riesgos y mostramos que este mecanismo puede ser utilizado abusivamente para interceptar tráfico en un clúster multi-tenant basado en namespaces. Más adelante, presentamos formas de mitigar esos riesgos.

## Ataques Man-in-the-Middle a través de VirtualService

En un entorno multi-tenant basado en namespaces, a menudo se asume que los namespaces proporcionan límites de confianza suficientes entre recursos de distintos namespaces. Sin embargo, la configuración de enrutamiento de tráfico de Istio opera a nivel de mesh, lo que significa que las reglas de enrutamiento definidas en un namespace influirán en el tráfico que se origina en workloads de otros namespaces.

Un atacante que tenga permiso para crear o modificar recursos `VirtualService` puede abusar de este comportamiento definiendo reglas de enrutamiento para hosts arbitrarios. Cuando el parámetro `mesh` de la service mesh se establece en la sección `gateways` de la especificación, las reglas de enrutamiento se aplican a todos los proxies sidecar de la mesh (independientemente de su namespace).

Esto permite a un atacante crear un `VirtualService` malicioso que coincida con solicitudes para nombres de host específicos y las redirija a un servicio controlado por el atacante. Como resultado, el tráfico de otros workloads de la mesh puede ser enrutado de forma transparente a través del servicio del atacante antes de llegar a su destino previsto.

Este comportamiento habilita ataques MITM dentro de la service mesh. El servicio controlado por el atacante puede interceptar tráfico de servicios de la mesh. Esto incluye tráfico hacia otros servicios de la mesh así como tráfico hacia servicios externos. Esto permite al atacante:

* actuar como el servicio de destino.
* redirigir el tráfico a destinos alternativos.
* descartar solicitudes para interrumpir la comunicación (denegación de servicio).

El servicio de origen enviará la solicitud al servicio controlado por el atacante en lugar del servicio de destino, ya que el `VirtualService` anula el comportamiento por defecto. La autenticación mTLS de Istio no ayuda aquí, porque el proxy identifica al servicio controlado por el atacante como el destino legítimo del hostname sobreescrito. Sin embargo, reenviar este tráfico al servicio de destino para leer o modificar la comunicación entre los dos servicios es más desafiante para el atacante, ya que no pueden eludir las [características de seguridad de capa 4 y capa 7 de Istio](/docs/overview/dataplane-modes/#layer-4-vs-layer-7-features). Al interceptar la comunicación, el cifrado y la autenticación de extremo a extremo entre el origen y el servicio de destino se rompen. Así, la solicitud reenviada desde el servicio controlado por el atacante al servicio de destino se autentica como una solicitud del servicio controlado por el atacante. Como resultado, las [Authorization Policies](/docs/reference/config/security/authorization-policy/) configuradas en el servicio de destino pueden denegar la solicitud. Además, el servicio de destino verá la identidad del servicio controlado por el atacante en el header `X-Forwarded-Client-Cert`, y la autenticación del servicio de origen se pierde.

## ¿Por qué ocurre este comportamiento?

Este comportamiento resulta de cómo Istio distribuye y evalúa la configuración de enrutamiento de tráfico dentro de la service mesh.

La service mesh de Istio se divide lógicamente en un data plane y un control plane. El control plane de Istio agrega la configuración de enrutamiento de todos los recursos `VirtualService` y distribuye la configuración resultante a los proxies sidecar de Envoy que conforman el data plane. Estos proxies luego aplican las reglas de enrutamiento localmente para el tráfico que manejan; ver también la [Arquitectura de Istio](/docs/ops/deployment/architecture/).

Cuando un `VirtualService` se configura como mesh gateway, sus reglas de enrutamiento se aplican a todos los sidecars de la mesh, incluyendo el tráfico interno servicio a servicio. Dado que los efectos de esta configuración no se limitan al namespace en que reside el `VirtualService`, una configuración creada en un namespace puede coincidir con solicitudes que se originen en workloads de otros namespaces.

## Mitigación y buenas prácticas

Los operadores que ejecutan Istio en configuraciones multi-tenant basadas en namespaces o que operan una única mesh en múltiples clústeres deben aplicar salvaguardas adicionales para mantener un aislamiento sólido. Sin estos controles, puede ocurrir una manipulación de tráfico no intencionada entre namespaces a nivel del data plane.

### Mitigación recomendada: migrar a la Gateway API más reciente

Idealmente, los permisos para crear o modificar recursos de red de Istio (`networking.istio.io/v1` así como `security.istio.io/v1`) deben limitarse a los operadores de la plataforma responsables del enrutamiento global.

Como alternativa, los operadores pueden ofrecer a los inquilinos acceso a la más reciente [Gateway API](https://gateway-api.sigs.k8s.io/), que fue diseñada pensando en el soporte seguro entre namespaces. Sin embargo, los operadores de la plataforma aún necesitan controlar el acceso a los recursos compartidos, como los gateways.

El [Configuration Scoping](/docs/ops/configuration/mesh/configuration-scoping/#scoping-mechanisms) puede implementarse como un control adicional.

### Mitigación en configuraciones heredadas

Cuando estos cambios y restricciones no son factibles debido a requisitos empresariales u organizativos, las configuraciones de enrutamiento deben tener un alcance limitado a servicios o namespaces específicos. Deben evitarse las reglas amplias que afectan a toda la mesh, a menos que sean explícitamente necesarias y sus implicaciones sean bien comprendidas.

Una forma de mitigar este tipo de ataque es configurar el [Scoping](/docs/ops/configuration/mesh/configuration-scoping/#scoping-mechanisms). Por ejemplo, restringir el [Egress listener en cada namespace](/docs/reference/config/networking/sidecar/#IstioEgressListener) a namespaces de confianza. Sin embargo, esto solo mitigaría el problema en modo sidecar y en modo ambient con waypoints, pero no [en modo ambient solo con L4](/docs/ambient/overview/), ni para los hosts configurados cuando se usa un [Istio Gateway](/docs/reference/config/networking/gateway/).

Otra forma de mitigar este tipo de ataque es implementar una [política de admisión](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) que limite qué hosts pueden usarse en la sección `host` para cada inquilino. Esto también mitigará el problema en modo ambient.

## Conclusión

Como se muestra en esta publicación, la opción mesh gateway de Istio permite que las reglas definidas en un namespace afecten el tráfico de otros namespaces. En configuraciones multi-tenant basadas en namespaces o al ejecutar una única mesh en múltiples clústeres, este comportamiento puede exponer la service mesh a actores maliciosos, por ejemplo habilitando ataques MITM, como se explica en esta publicación.

Istio no pretende (ni busca pretender) el multi-tenancy estricto basado en namespaces, ya que el proyecto eligió el compromiso que facilita la adopción. Por tanto, los operadores que dependen de este tipo de multi-tenancy deben evaluar los riesgos involucrados en su arquitectura y abordar las debilidades, por ejemplo eliminando permisos RBAC innecesarios y aplicando controles de admisión estrictos.

## Referencias

* [Documentación de Istio — Modelo de seguridad](/docs/ops/deployment/security-model/#k8s-account-compromise)
* [Boletín de seguridad ISTIO-SECURITY-2026-002](/news/security/istio-security-2026-002/)
* [Documentación de Istio — Gestión de tráfico](/docs/concepts/traffic-management/)
* [Documentación de Istio — VirtualService](/docs/reference/config/networking/virtual-service/)
