---
title: "Presentamos el Operador Sail: una nueva forma de gestionar Istio"
description: Presentamos el Operador Sail para gestionar Istio, un proyecto que forma parte de la organización istio-ecosystem.
publishdate: 2024-08-19
attribution: "Francisco Herrera - Red Hat"
keywords: [istio,operator,sail,incluster,deprecation]
---

Con el reciente anuncio de la [desaprobación](/blog/2024/in-cluster-operator-deprecation-announcement/) del IstioOperator In-Cluster en Istio 1.23 y su posterior eliminación para Istio 1.24, queremos dar a conocer un
[nuevo operador](https://github.com/istio-ecosystem/sail-operator) que el equipo de Red Hat ha estado desarrollando para gestionar Istio como parte de la organización [istio-ecosystem](https://github.com/istio-ecosystem).

El Operador Sail gestiona el ciclo de vida de los control planes de Istio, lo que facilita y hace más eficiente para los administradores de clusteres el despliegue, la configuración y la actualización de Istio en entornos de producción a gran escala. En lugar de
crear un nuevo esquema de configuración y reinventar la rueda, las API del Operador Sail se basan en las API de los charts de Helm de Istio. Todas las opciones de instalación y configuración que exponen los charts de Helm de Istio están disponibles
a través de los campos de valores de las CRD del Operador Sail. Esto significa que puedes gestionar y personalizar fácilmente Istio utilizando configuraciones familiares sin necesidad de aprender elementos adicionales.

El Operador Sail tiene 3 conceptos de recursos principales:
* [Istio](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istio-resource): se utiliza para gestionar los control planes de Istio.
* [Istio Revision](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiorevision-resource): representa una revisión de ese control plane, que es una instancia de Istio con una versión y un nombre de revisión específicos.
* [Istio CNI](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiocni-resource): se utiliza para gestionar el recurso y el ciclo de vida del complemento CNI de Istio. Para instalar el complemento CNI de Istio, se crea un recurso `IstioCNI`.

Actualmente, la característica principal del Operador Sail es la Estrategia de Actualización. El operador proporciona una interfaz que gestiona la actualización del (los) control plane(s) de Istio. Actualmente admite dos estrategias de actualización:
* [In Place](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#inplace): con la estrategia `InPlace`, el control plane de Istio existente se reemplaza por una nueva versión, y los sidecars de el workload
  se conectan inmediatamente al nuevo control plane. De esta manera, los workloads no necesitan ser movidas de una instancia de control plane a otra.
* [Revision Based](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#revisionbased): con la estrategia `RevisionBased`, se crea una nueva instancia del control plane de Istio para cada cambio en el
  campo `Istio.spec.version`. El antiguo control plane permanece en su lugar hasta que todas los workloads se hayan movido a la nueva instancia del control plane. Opcionalmente, se puede establecer la bandera `updateWorkloads` para mover automáticamente
  los workloads al nuevo control plane cuando esté listo.

Sabemos que realizar actualizaciones del control plane de Istio conlleva riesgos y puede requerir un esfuerzo manual sustancial para grandes despliegues, y es por eso que es nuestro enfoque actual. Para el futuro, estamos estudiando cómo el
Operador Sail puede dar un mejor soporte a casos de uso como la multi-tenencia y el aislamiento, la federación multi-cluster y la integración simplificada con proyectos de terceros.

El proyecto del Operador Sail todavía está en fase alfa y en pleno desarrollo. Ten en cuenta que, como proyecto de istio-ecosystem, no cuenta con el soporte del proyecto Istio. Buscamos activamente comentarios y contribuciones de la
comunidad. Si quieres involucrarte en el proyecto, consulta la [documentación](https://github.com/istio-ecosystem/sail-operator/blob/main/README.md) del repositorio y las [directrices de contribución](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md). Si eres un
usuario, también puedes probar el nuevo operador siguiendo las instrucciones de la
[documentación del usuario](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md).

Para más información, contáctanos:

* [Discusiones](https://github.com/istio-ecosystem/sail-operator/discussions)
* [Incidencias](https://github.com/istio-ecosystem/sail-operator/issues)
* [Slack](https://istio.slack.com/archives/C06SE9XCK3Q)
