---
title: La service mesh de Istio
description: service mesh.
subtitle: Istio aborda los desafíos que enfrentan los desarrolladores y operadores con una arquitectura distribuida o de microservicios. Ya sea que esté construyendo desde cero, migrando aplicaciones existentes a la nube nativa o protegiendo su patrimonio existente, Istio puede ayudar.
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /service-mesh.html
    - /docs/concepts/what-is-istio/overview
    - /docs/concepts/what-is-istio/goals
    - /about/intro
    - /docs/concepts/what-is-istio/
    - /latest/docs/concepts/what-is-istio/
doc_type: about
---

{{< centered_block >}}
{{< figure src="/img/service-mesh.svg" alt="service mesh" title="Al usar proxies de aplicaciones, Istio le permite programar una gestión del tráfico consciente de la aplicación, una observabilidad increíble y capacidades de seguridad sólidas en su red." >}}
{{< /centered_block >}}

{{< centered_block >}}

[comment]: <> (El siguiente encabezado solo está aquí porque el lint requiere que el primer encabezado sea un <h2>, y más adelante queremos <h1>s.)

## ¿Qué es Istio?

Una **service mesh** es una capa de infraestructura que brinda a las aplicaciones capacidades como seguridad de confianza cero, observabilidad y gestión avanzada del tráfico, sin cambios en el código. **Istio** es la service mesh más popular, potente y confiable. Fundada por Google, IBM y Lyft en 2016, Istio es un proyecto graduado en la Cloud Native Computing Foundation junto con proyectos como Kubernetes y Prometheus.

Istio garantiza que los sistemas nativos de la nube y distribuidos sean resistentes, lo que ayuda a las empresas modernas a mantener sus workloads en diversas plataformas mientras se mantienen conectadas y protegidas. [Habilita los controles de seguridad y gobernanza](/es/docs/concepts/observability/) que incluyen el cifrado mTLS, la gestión de políticas y el control de acceso, [potencia las funciones de red](/es/docs/concepts/traffic-management/) como las implementaciones canarias, las pruebas A/B, el equilibrio de carga, la recuperación de fallas y [agrega observabilidad](/es/docs/concepts/observability/) del tráfico en todo su patrimonio.

Istio no se limita a los límites de un solo cluster, red o tiempo de ejecución: los servicios que se ejecutan en Kubernetes o máquinas virtuales, multinube, híbridos o locales, se pueden incluir en una sola malla.

Extensible por diseño y respaldado por un [amplio ecosistema](/about/ecosystem) de contribuyentes y socios, Istio ofrece integraciones y distribuciones empaquetadas para diversos casos de uso. Puede instalar Istio de forma independiente u optar por el soporte administrado de proveedores comerciales que brindan soluciones basadas en Istio.

<div class="cta-container">
    <a class="btn" href="/es/docs/overview/">Más información sobre Istio</a>
</div>

{{< /centered_block >}}

<br/><br/>

# Características

{{< feature_block header="Seguro por defecto" image="security.svg" >}}
Istio proporciona una solución de zero-trust líder en el mercado basada en la identidad de el workload, TLS mutuo y controles de políticas sólidos. Istio ofrece el valor de [BeyondProd](https://cloud.google.com/security/beyondprod/) en código abierto, al tiempo que evita el bloqueo de proveedores o los SPOF.

<a class="btn" href="/es/docs/concepts/security/">Más información sobre seguridad</a>
{{< /feature_block>}}

{{< feature_block header="Aumentar la observabilidad" image="observability.svg" >}}
Istio genera telemetría dentro de la service mesh, lo que permite la observabilidad del comportamiento del servicio. Se integra con sistemas APM, incluidos Grafana y Prometheus, para ofrecer métricas detalladas para que los operadores solucionen problemas, mantengan y optimicen las aplicaciones.

<a class="btn" href="/es/docs/concepts/observability/">Más información sobre la observabilidad</a>
{{< /feature_block>}}

{{< feature_block header="Gestionar el tráfico" image="management.svg" >}}
Istio simplifica el enrutamiento del tráfico y la configuración a nivel de servicio, lo que permite un fácil control sobre el flujo entre los servicios y la configuración de tareas como las pruebas A/B, las implementaciones canarias y los despliegues por etapas con divisiones de tráfico basadas en porcentajes.

<a class="btn" href="/es/docs/concepts/traffic-management/">Más información sobre la gestión del tráfico</a>
{{< /feature_block>}}

<br/><br/>

# ¿Por qué Istio?

{{< feature_block header="Múltiples modos de implementación" image="deployment-modes.svg" >}}
Istio ofrece dos modos de data plane para que los usuarios elijan. Implemente con el nuevo modo ambient para un ciclo de vida operativo de la aplicación simplificado o con sidecars tradicionales para configuraciones complejas.

<a class="btn" href="/es/docs/overview/data plane-modes/">Más información sobre los modos del data plane</a>
{{< /feature_block>}}

{{< feature_block header="Impulsado por Envoy" image="envoy.svg" >}}
Construido sobre el proxy de gateway estándar de la industria para aplicaciones nativas de la nube, Istio es altamente performante y extensible por diseño. Agregue una funcionalidad de tráfico personalizada con WebAssembly o integre sistemas de políticas de terceros.

<a class="btn" href="/es/docs/overview/why-choose-istio/#envoy">Más información sobre Istio y Envoy</a>
{{< /feature_block>}}

{{< feature_block header="Un verdadero proyecto comunitario" image="community-project.svg" >}}
Istio ha sido diseñado para workloads modernas y diseñado por una vasta comunidad de innovadores en todo el panorama nativo de la nube.

<a class="btn" href="/es/docs/overview/why-choose-istio/#community">Más información sobre los contribuyentes de Istio</a>
{{< /feature_block>}}

{{< feature_block header="Despliegue binarios estables" image="stable-releases.svg" >}}
Implemente Istio con confianza en los workloads de producción. Todas las versiones son totalmente accesibles sin costo alguno.

<a class="btn" href="/es/docs/overview/why-choose-istio/#packages">Más información sobre cómo se empaqueta Istio</a>
{{< /feature_block>}}
