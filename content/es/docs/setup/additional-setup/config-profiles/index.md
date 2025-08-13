---
title: Perfiles de Configuración de Instalación
description: Describe los perfiles de configuración de instalación incorporados de Istio.
weight: 35
aliases:
    - /docs/setup/kubernetes/additional-setup/config-profiles/
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

Esta página describe los perfiles de configuración incorporados que pueden usarse al
[instalar Istio](/es/docs/setup/install).

Los perfiles de configuración son simplemente grupos nombrados de sobrescrituras de valores de charts de Helm que están incorporados en los charts,
y pueden usarse al instalar a través de `helm` o `istioctl`.

Los perfiles proporcionan personalización de alto nivel del control plane y data plane de Istio para topologías de deployment comunes y plataformas objetivo.

{{< tip >}}
Los perfiles de configuración se componen con otras sobrescrituras de valores o flags, por lo que cualquier valor individual que establezca un perfil de configuración puede ser sobrescrito manualmente especificando un flag `--set` después de él en el comando.
{{< /tip >}}

Hay 2 tipos de perfiles de configuración: perfiles de _deployment_ y perfiles de _platform_, y se recomienda usar ambos.

- Los perfiles de _deployment_ están destinados a proporcionar buenos valores por defecto para una topología de deployment dada (`default`, `remote`, `ambient`, etc).
- Los perfiles de _platform_ están destinados a proporcionar valores por defecto necesarios específicos de la plataforma, para una plataforma objetivo dada (`eks`, `gke`, `openshift`, etc).

Por ejemplo, si estás instalando el data plane sidecar `default` en GKE, recomendamos usar los siguientes perfiles de deployment y platform para comenzar:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    Para Helm, proporciona el mismo `profile` y `platform` para cada chart que instales, por ejemplo `istiod`:

    {{< text syntax=bash snip_id=install_istiod_helm_platform >}}
    $ helm install istiod istio/istiod -n istio-system --set profile=default --set global.platform=gke --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    Para `istioctl`, proporciona el mismo `profile` y `platform` como argumentos:

    {{< text syntax=bash snip_id=install_istiod_istioctl_platform >}}
    $ istioctl install --set profile=default --set values.global.platform=gke
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< warning >}}
Note que una diferencia clave entre los mecanismos de instalación `helm` y `istioctl` es que los perfiles de configuración de `istioctl` también incluyen una lista de componentes de Istio que se instalarán automáticamente por `istioctl`.

Con `helm`, esto no es el caso - los usuarios esperan instalar cada componente requerido de Istio individualmente a través de `helm install`, y proporcionar los flags de perfil de configuración deseados para cada componente manualmente.

Puedes pensar en esto como `istioctl` y `helm` compartiendo exactamente los mismos perfiles de configuración con los mismos nombres, pero cuando usas `istioctl`, también elegirá qué componentes instalar para ti basándote en el perfil de configuración que selecciones, por lo que solo se necesita un comando para lograr el mismo resultado.
{{< /warning >}}

## Perfiles de Deployment

Los siguientes perfiles de deployment incorporados actualmente están disponibles para ambos mecanismos de instalación `istioctl` y `helm`. Tenga en cuenta que, como estos son solo conjuntos de sobrescrituras de valores de Helm, su uso no es estrictamente necesario para instalar Istio, pero proporcionan una línea de base conveniente y se recomiendan para nuevas instalaciones. Además, puede [personalizar la configuración](/es/docs/setup/additional-setup/customize-installation/)
más allá de lo que incluye el perfil de deployment, para sus necesidades específicas. Los siguientes perfiles de deployment incorporados actualmente están disponibles:

1. **default**: habilita componentes según los valores por defecto del
    [`IstioOperator` API](/es/docs/reference/config/istio.operator.v1alpha1/).
    Este perfil se recomienda para implementaciones de producción y para
    {{< gloss "primary cluster" >}}clusters primarios{{< /gloss >}} en una
    [mesh multicluster](/es/docs/ops/deployment/deployment-models/#multiple-clusters).

1. **demo**: configuración diseñada para mostrar la funcionalidad de Istio con requisitos de recursos modestos.
    Es adecuado para ejecutar la [Bookinfo](/es/docs/examples/bookinfo/) aplicación y tareas asociadas.
    Esta es la configuración que se instala con las instrucciones de [inicio rápido](/es/docs/setup/getting-started/).

    {{< warning >}}
    Este perfil habilita niveles altos de seguimiento y registro de acceso, por lo que no es adecuado para pruebas de rendimiento.
    {{< /warning >}}

1. **minimal**: igual que el perfil por defecto, pero solo se instalan los componentes del control plane.
    Esto te permite configurar los componentes del control plane y data plane (por ejemplo, puertas de enlace) usando [perfiles separados](/es/docs/setup/additional-setup/gateway/#deploying-a-gateway).

1. **remote**: utilizado para configurar un {{< gloss >}}remote cluster{{< /gloss >}} que es administrado por un
    {{< gloss >}}external control plane{{< /gloss >}} o por un control plane en un {{< gloss >}}primary cluster{{< /gloss >}}
    de una [mesh multicluster](/es/docs/ops/deployment/deployment-models/#multiple-clusters).

1. **ambient**: el perfil de ambiente está diseñado para ayudarte a comenzar con [modo ambiente](/es/docs/ambient).

1. **empty**: implementa nada. Esto puede ser útil como un perfil base para la configuración personalizada.

1. **preview**: el perfil de vista previa contiene características que son experimentales. Este es intencionado para explorar nuevas características
                que vienen a Istio. La estabilidad, la seguridad y el rendimiento no están garantizados - use bajo su propio riesgo.

Los [perfiles de deployment de Istio están definidos aquí]({{< github_tree >}}/manifests/helm-profiles), para ambos `istioctl` y `helm`.

Para `istioctl` solo, la especificación de perfiles de configuración también selecciona automáticamente ciertos componentes de Istio para su instalación, como se marca con &#x2714; a continuación:

|     | default | demo | minimal | remote | empty | preview | ambient |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Componentes principales | | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | &#x2714; | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | &#x2714; | &#x2714; | | | | &#x2714; | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istiod` | &#x2714; | &#x2714; | &#x2714; | | | &#x2714; | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`CNI` | | | | | | | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`Ztunnel` | | | | | | | &#x2714; |

{{< tip >}}
Para personalizar aún más Istio, también se pueden instalar componentes de complemento.
Consulta [integraciones](/es/docs/ops/integrations) para más detalles.
{{< /tip >}}

## Perfiles de Plataforma

Los siguientes perfiles de plataforma incorporados actualmente están disponibles para ambos mecanismos de instalación `istioctl` y `helm`. Tenga en cuenta que, como estos son solo conjuntos de sobrescrituras de valores de Helm, su uso no es estrictamente necesario para instalar Istio en estos entornos, pero proporcionan una línea de base conveniente y se recomiendan para nuevas instalaciones:

1. **gke**: Establece opciones de gráfico requeridas o recomendadas para instalar Istio en entornos de Google Kubernetes Engine (GKE).

1. **eks**: Establece opciones de gráfico requeridas o recomendadas para instalar Istio en entornos de Amazon Elastic Kubernetes Service (EKS).

1. **openshift**: Establece opciones de gráfico requeridas o recomendadas para instalar Istio en entornos de OpenShift.

1. **k3d**: Establece opciones de gráfico requeridas o recomendadas para instalar Istio en [k3d](https://k3d.io/) entornos.

1. **k3s**: Establece opciones de gráfico requeridas o recomendadas para instalar Istio en [K3s](https://k3s.io/) entornos.

1. **microk8s**: Establece opciones de gráfico requeridas o recomendadas para instalar Istio en [MicroK8s](https://microk8s.io/) entornos.

1. **minikube**: Establece opciones de gráfico requeridas o recomendadas para instalar Istio en [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) entornos.

Los [perfiles de plataforma de Istio están definidos aquí]({{< github_tree >}}/manifests/helm-profiles), para ambos `istioctl` y `helm`.
