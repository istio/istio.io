---
title: "Lanzamiento de Sail Operator 1.0.0: gestiona Istio con un operador"
description: Sumérgete en los conceptos básicos del Operador Sail y echa un vistazo a un ejemplo para ver lo fácil que es usarlo para gestionar Istio.
publishdate: 2025-04-03
attribution: "Francisco Herrera - Red Hat"
keywords: [istio,operator,sail,incluster,istiooperator]
---

El [Operador Sail](https://github.com/istio-ecosystem/sail-operator) es un proyecto comunitario lanzado por Red Hat para construir un [operador](https://www.redhat.com/en/topics/containers/what-is-a-kubernetes-operator) moderno para Istio. [Anunciado por primera vez en agosto de 2024](/blog/2024/introducing-sail-operator/), nos complace anunciar que el Operador Sail ya es GA con una misión clara: simplificar y agilizar la gestión de Istio en tu cluster.

## Despliegue y gestión simplificados

El Operador Sail está diseñado para reducir la complejidad de instalar y ejecutar Istio. Automatiza las tareas manuales, garantizando una experiencia consistente, fiable y sin complicaciones desde la instalación inicial hasta el mantenimiento y las actualizaciones continuas de las versiones de Istio en tu cluster. Las API del Operador Sail se basan en las API de los charts de Helm de Istio, lo que significa que todas las configuraciones de Istio están disponibles a través de los valores de las CRD del Operador Sail.

Animamos a los usuarios a que consulten nuestra [documentación](https://github.com/istio-ecosystem/sail-operator/tree/main/docs) para obtener más información sobre esta nueva forma de gestionar su entorno de Istio.

Los principales recursos que forman parte del Operador Sail son:
* `Istio`: gestiona un control plane de Istio.
* `IstioRevision`: representa una revisión del control plane.
* `IstioRevisionTag`: representa una etiqueta de revisión estable, que funciona como un alias para una revisión del control plane de Istio.
* `IstioCNI`: gestiona el agente de nodo CNI de Istio.
* `ZTunnel`: gestiona el DaemonSet ztunnel del modo ambient (característica Alfa).

{{< idea >}}
Si estás migrando desde el [operador in-cluster de Istio ya eliminado](/blog/2024/in-cluster-operator-deprecation-announcement/), puedes consultar esta sección en nuestra [documentación](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#migrating-from-istio-in-cluster-operator) donde explicamos la equivalencia de recursos, o también puedes probar nuestro [convertidor de recursos](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#converter-script) para convertir fácilmente tu recurso `IstioOperator` a un recurso `Istio`.
{{< /idea >}}

## Características principales y soporte

- Cada componente del control plane de Istio es gestionado de forma independiente por el Operador Sail a través de Recursos Personalizados (CR) de Kubernetes dedicados. El Operador Sail proporciona CRD separadas para componentes como `Istio`, `IstioCNI` y `ZTunnel`, lo que te permite configurarlos, gestionarlos y actualizarlos individualmente. Además, hay CRD para `IstioRevision` e `IstioRevisionTag` para gestionar las revisiones del control plane de Istio.
- Soporte para múltiples versiones de Istio. Actualmente, la versión 1.0.0 admite: 1.24.3, 1.24.2, 1.24.1, 1.23.5, 1.23.4, 1.23.3, 1.23.0.
- Se admiten dos estrategias de actualización: `InPlace` y `RevisionBased`. Consulta nuestra documentación para obtener más información sobre los tipos de actualización admitidos.
- Soporte para [modelos de despliegue](/es/docs/setup/install/multicluster/) de Istio multicluster: multi-primario, primario-remoto, control plane externo. Más información y ejemplos en nuestra [documentación](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#multi-cluster).
- El soporte del modo ambient es Alfa: consulta nuestra [documentación](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/common/istio-ambient-mode.md) específica.
- Los complementos se gestionan por separado del Operador Sail. Se pueden integrar fácilmente con el Operador Sail, consulta esta sección de la [documentación](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#addons) para ver ejemplos y más información.

## ¿Por qué ahora?

A medida que las arquitecturas nativas de la nube continúan evolucionando, creemos que un operador robusto y fácil de usar para Istio es más esencial que nunca. El Operador Sail ofrece a los equipos de desarrollo y operaciones una solución consistente, segura y eficiente que resulta familiar para aquellos acostumbrados a trabajar con operadores. Su lanzamiento GA señala una solución madura, lista para soportar incluso los entornos de producción más exigentes.

## Pruébalo

¿Te gustaría probar el Operador Sail?
Este ejemplo te mostrará cómo realizar una actualización segura de tu control plane de Istio utilizando la estrategia de actualización basada en revisiones. Esto significa que tendrás dos control planes de Istio ejecutándose al mismo tiempo, lo que te permitirá migrar los workloads fácilmente, minimizando el riesgo de interrupciones del tráfico.

Prerrequisitos:
- cluster en ejecución
- Helm
- Kubectl
- Istioctl

### Instalar el Operador Sail usando Helm

{{< text bash >}}
$ helm repo add sail-operator https://istio-ecosystem.github.io/sail-operator
$ helm repo update
$ kubectl create namespace sail-operator
$ helm install sail-operator sail-operator/sail-operator --version 1.0.0 -n sail-operator
{{< /text >}}

El operador ya está instalado en tu cluster:

{{< text plain >}}
NAME: sail-operator
LAST DEPLOYED: Tue Mar 18 12:00:46 2025
NAMESPACE: sail-operator
STATUS: deployed
REVISION: 1
TEST SUITE: None
{{< /text >}}

Comprueba que el pod del operador se está ejecutando:

{{< text bash >}}
$ kubectl get pods -n sail-operator
NAME                             READY   STATUS    RESTARTS   AGE
sail-operator-56bf994f49-j67ft   1/1     Running   0          87s
{{< /text >}}

### Crear recursos `Istio` e `IstioRevisionTag`

Crea un recurso `Istio` con la versión `v1.24.2` y un `IstioRevisionTag`:

{{< text bash >}}
$ kubectl create ns istio-system
$ cat <<EOF | kubectl apply -f-
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: RevisionBased
    inactiveRevisionDeletionGracePeriodSeconds: 30
  version: v1.24.2
---
apiVersion: sailoperator.io/v1
kind: IstioRevisionTag
metadata:
  name: default
spec:
  targetRef:
    kind: Istio
    name: default
EOF
{{< /text >}}

Ten en cuenta que el `IstioRevisionTag` tiene una referencia de destino al recurso `Istio` con el nombre `default`

Comprueba el estado de los recursos creados:
- los pods de `istiod` se están ejecutando

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-2-bd8458c4-jl8zm   1/1     Running   0          3m45s
    {{< /text >}}

- Recurso `Istio` creado

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-2   Healthy   v1.24.2   4m27s
    {{< /text >}}

- Recurso `IstioRevisionTag` creado

    {{< text bash >}}
    $ kubectl get istiorevisiontag
    NAME      STATUS                    IN USE   REVISION          AGE
    default   NotReferencedByAnything   False    default-v1-24-2   4m43s
    {{< /text >}}

Ten en cuenta que el estado de `IstioRevisionTag` es `NotReferencedByAnything`. Esto se debe a que actualmente no hay recursos que utilicen la revisión `default-v1-24-2`.

### Desplegar aplicación de ejemplo

Crea un namespace y etiquétalo para habilitar la inyección de Istio:

{{< text bash >}}
$ kubectl create namespace sample
$ kubectl label namespace sample istio-injection=enabled
{{< /text >}}

Después de etiquetar el namespace, verás que el estado del recurso `IstioRevisionTag` cambiará a 'In Use: True', porque ahora hay un recurso que utiliza la revisión `default-v1-24-2`:

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-2   6m24s
{{< /text >}}

Despliega la aplicación de ejemplo:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml -n sample
{{< /text >}}

Confirma que la versión del proxy de la aplicación de ejemplo coincide con la versión del control plane:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

### Actualizar el control plane de Istio a la versión 1.24.3

Actualiza el recurso `Istio` con la nueva versión:

{{< text bash >}}
$ kubectl patch istio default -n istio-system --type='merge' -p '{"spec":{"version":"v1.24.3"}}'
{{< /text >}}

Comprueba el recurso `Istio`. Verás que hay dos revisiones y que ambas están 'listas':

{{< text bash >}}
$ kubectl get istio
NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
default   2           2       2        default-v1-24-3   Healthy   v1.24.3   10m
{{< /text >}}

El `IstioRevisiontag` ahora hace referencia a la nueva revisión:

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-3   11m
{{< /text >}}

Hay dos `IstioRevisions`, una para cada versión de Istio:

{{< text bash >}}
$ kubectl get istiorevision
NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
default-v1-24-2          True    Healthy   True     v1.24.2   11m
default-v1-24-3          True    Healthy   True     v1.24.3   92s
{{< /text >}}

El Operador Sail detecta automáticamente si un determinado control plane de Istio se está utilizando y escribe esta información en la condición de estado "In Use" que ves arriba. En este momento, todas las `IstioRevisions` y nuestro `IstioRevisionTag` se consideran "In Use":
* La revisión antigua `default-v1-24-2` se considera en uso porque es referenciada por el sidecar de la aplicación de ejemplo.
* La nueva revisión `default-v1-24-3` se considera en uso porque es referenciada por la etiqueta.
* La etiqueta se considera en uso porque es referenciada por el namespace de ejemplo.

Confirma que hay dos pods del control plane en ejecución, uno para cada revisión:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                      READY   STATUS    RESTARTS   AGE
istiod-default-v1-24-2-bd8458c4-jl8zm     1/1     Running   0          16m
istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          6m32s
{{< /text >}}

Confirma que la versión del sidecar del proxy sigue siendo la misma:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS                LDS                EDS                RDS                ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

Reinicia el pod de ejemplo:

{{< text bash >}}
$ kubectl rollout restart deployment -n sample
{{< /text >}}

Confirma que la versión del sidecar del proxy está actualizada:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                      VERSION
sleep-6f87fcf556-k9nh9.sample     Kubernetes     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     IGNORED     istiod-default-v1-24-3-68df97dfbb-v7ndm     1.24.3
{{< /text >}}

Cuando una `IstioRevision` ya no está en uso y no es la revisión activa de un recurso `Istio` (por ejemplo, cuando no es la versión que se establece en el campo `spec.version`), el Operador Sail la eliminará después de un período de gracia, que por defecto es de 30 segundos. Confirma la eliminación del antiguo control plane e `IstioRevision`:

- El pod del antiguo control plane se elimina

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                      READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          10m
    {{< /text >}}

- La antigua `IstioRevision` se elimina

    {{< text bash >}}
    $ kubectl get istiorevision
    NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
    default-v1-24-3          True    Healthy   True     v1.24.3   13m
    {{< /text >}}

- El recurso `Istio` ahora solo tiene una revisión

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-3   Healthy   v1.24.3   24m
    {{< /text >}}

**¡Felicidades!** Has actualizado correctamente tu control plane de Istio utilizando la estrategia de actualización basada en revisiones.

{{< idea >}}
Para comprobar la última versión del Operador Sail, visita nuestra [página de releases](https://github.com/istio-ecosystem/sail-operator/releases). Como este ejemplo puede evolucionar con el tiempo, consulta nuestra [documentación](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#example-using-the-revisionbased-strategy-and-an-istiorevisiontag) para asegurarte de que estás leyendo la versión más actualizada.
{{< /idea >}}

## Conclusión

El Operador Sail automatiza las tareas manuales, garantizando una experiencia consistente, fiable y sin complicaciones desde la instalación inicial hasta el mantenimiento y las actualizaciones continuas de Istio en tu cluster. El Operador Sail es un proyecto de [istio-ecosystem](https://github.com/istio-ecosystem), y te animamos a que lo pruebes y nos des tu opinión para ayudarnos a mejorarlo. Puedes consultar nuestra [guía de contribución](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md) para obtener más información sobre cómo contribuir al proyecto.
