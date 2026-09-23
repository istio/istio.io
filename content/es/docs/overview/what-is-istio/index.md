---
title: ¿Qué es Istio?
description: Descubre qué puede hacer Istio por ti.
weight: 10
keywords: [introduction]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Istio es un service mesh de código abierto que se superpone de forma transparente sobre las aplicaciones distribuidas existentes. Las potentes características de Istio proporcionan una forma uniforme y más eficiente de asegurar, conectar y monitorear servicios. Istio es el camino hacia el balanceo de carga, la autenticación service-to-service y el monitoreo, con pocos o ningún cambio en el código del servicio. Te proporciona:

* Comunicación segura service-to-service en un cluster con cifrado mutual TLS, autenticación y autorización basada en identidad fuerte
* Balanceo de carga automático para tráfico HTTP, gRPC, WebSocket y TCP
* Control granular del comportamiento del tráfico con reglas de enrutamiento ricas, reintentos, failovers e inyección de fallos
* Una capa de política conectiva y API de configuración que soporta controles de acceso, límites de velocidad y cuotas
* Métricas, logs y trazas automáticas para todo el tráfico dentro de un cluster, incluyendo ingreso y egreso del cluster

Istio está diseñado para la extensibilidad y puede manejar una amplia gama de necesidades de deployment. El {{< gloss >}}control plane{{< /gloss >}} de Istio se ejecuta en Kubernetes, y puedes agregar aplicaciones desplegadas en ese cluster a tu malla, [extender la mesh a otros clusters](/es/docs/ops/deployment/deployment-models/), o incluso [conectar VMs u otros endpoints](/es/docs/ops/deployment/vm-architecture/) ejecutándose fuera de Kubernetes.

Un gran ecosistema de contribuyentes, socios, integraciones y distribuidores extiende y aprovecha Istio para una amplia variedad de escenarios. Puedes instalar Istio tú mismo, o un [gran número de proveedores](/about/ecosystem) tienen productos que integran Istio y lo gestionan por ti.

## Cómo funciona

Istio usa un proxy para interceptar todo tu tráfico de red, permitiendo un amplio conjunto de características conscientes de aplicación basadas en la configuración que estableces.

El control plane toma tu configuración deseada, y su vista de los servicios, y programa dinámicamente los servidores proxy, actualizándolos a medida que las reglas o el entorno cambian.

El data plane es la comunicación entre servicios. Sin un service mesh, la red no entiende el tráfico que se envía, y no puede tomar decisiones basadas en qué tipo de tráfico es, o de quién es o hacia quién va.

Istio soporta dos modos de data plane:

* **modo sidecar**, que despliega un proxy Envoy junto con cada Pod que inicias en tu cluster, o ejecutándose junto a servicios ejecutándose en VMs.
* **modo ambient**, que usa un proxy capa 4 por nodo, y opcionalmente un proxy Envoy por Namespace para características de capa 7.

[Aprende cómo elegir qué modo es el correcto para ti](/es/docs/overview/dataplane-modes/).
