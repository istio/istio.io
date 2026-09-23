---
title: "Istio ha desaprobado su Operador In-Cluster"
description: Lo que necesitas saber si estás ejecutando el controlador del Operador en tu cluster.
publishdate: 2024-08-14
attribution: "Mitch Connors (Microsoft), para el Comité de Supervisión Técnica de Istio"
keywords: [operator,deprecation]
---

El Operador In-Cluster de Istio ha sido desaprobado en Istio 1.23. Los usuarios que aprovechan el operador, que estimamos que son menos del 10% de nuestra base de usuarios, deberán migrar a otros mecanismos de instalación y actualización para poder actualizar a Istio 1.24 o superior. Sigue leyendo para saber por qué estamos haciendo este cambio y qué deben hacer los usuarios del operador.

## ¿Te afecta esto?

Esta desaprobación solo afecta a los usuarios del [Operador In-Cluster](https://archive.istio.io/v1.23/docs/setup/install/operator/). **Los usuarios que instalan Istio con el comando <code>istioctl install</code> y un archivo YAML `IstioOperator` no se ven afectados**.

Para determinar si te afecta, ejecuta `kubectl get deployment -n istio-system istio-operator` y `kubectl get IstioOperator`. Si ambos comandos devuelven valores no vacíos, tu cluster se verá afectado. Según encuestas recientes, esperamos que esto afecte a menos del 10% de los usuarios de Istio.

Las instalaciones de Istio basadas en el Operador seguirán funcionando indefinidamente, pero no se podrán actualizar más allá de la 1.23.x.

## ¿Cuándo necesito migrar?

De acuerdo con la política de desaprobación de Istio para las características Beta, el Operador In-Cluster de Istio se eliminará con el lanzamiento de Istio 1.24, aproximadamente tres meses después de este anuncio. Istio 1.23 será compatible hasta marzo de 2025, momento en el que los usuarios del operador deberán migrar a otro mecanismo de instalación para mantener el soporte.

## ¿Cómo migro?

El proyecto Istio seguirá admitiendo la instalación y actualización a través del comando `istioctl`, así como con Helm. Debido a la popularidad de Helm dentro del ecosistema de ingeniería de plataformas, recomendamos que la mayoría de los usuarios migren a Helm. `istioctl install` se basa en plantillas de Helm, y las versiones futuras pueden integrarse más profundamente con Helm.

Las instalaciones de Helm también se pueden gestionar con herramientas de GitOps como [Flux](https://fluxcd.io/) o [Argo CD](https://argo-cd.readthedocs.io/).

Los usuarios que prefieran el patrón de operador para ejecutar Istio pueden migrar a cualquiera de los dos nuevos proyectos del Ecosistema de Istio, el Classic Operator Controller o el Sail Operator.

### Migración a Helm

La migración a Helm requiere traducir tu YAML de `IstioOperator` a valores de Helm. Istio 1.24 y superior incluye un comando `manifest translate` para realizar esta operación. La salida es un archivo `values.yaml` y un script de shell para instalar los charts de Helm equivalentes.

{{< text bash >}}
$ istioctl manifest translate -f istio.yaml
{{< /text >}}

### Migración a istioctl

Identifica tu recurso personalizado `IstioOperator`: solo debería haber un resultado.

{{< text bash >}}
$ kubectl get IstioOperator
{{< /text >}}

Usando el nombre de tu recurso, descarga la configuración de tu operador en formato YAML:

{{< text bash >}}
$ kubectl get IstioOperator <name> -o yaml > istio.yaml
{{< /text >}}

Deshabilita el Operador In-Cluster. Esto no deshabilitará tu control plane ni interrumpirá el tráfico de tu mesh actual.

{{< text bash >}}
$ kubectl scale deployment -n istio-system istio-operator –replicas 0
{{< /text >}}

Cuando estés listo para actualizar Istio a la versión 1.24 o posterior, sigue [las instrucciones de actualización](/es/docs/setup/upgrade/canary/), usando el archivo `istio.yaml` que descargaste anteriormente.

Una vez que hayas completado y verificado tu migración, ejecuta los siguientes comandos para limpiar los recursos de tu operador:

{{< text bash >}}
$ kubectl delete deployment -n istio-system istio-operator
$ kubectl delete customresourcedefinition istiooperator
{{< / text >}}

### Migración al Classic Operator Controller

Un nuevo proyecto del ecosistema, el [Classic Operator Controller](https://github.com/istio-ecosystem/classic-operator-controller), es una bifurcación del controlador original integrado en Istio. Este proyecto mantiene la misma API y base de código que el operador original, pero se mantiene fuera del núcleo de Istio.

Debido a que la API es la misma, la migración es sencilla: solo se requerirá la instalación del nuevo operador.

El Classic Operator Controller no es compatible con el proyecto Istio.

### Migración al Sail Operator

Un nuevo proyecto del ecosistema, el [Sail Operator](https://github.com/istio-ecosystem/sail-operator), puede instalar y gestionar el ciclo de vida del control plane de Istio en un cluster de Kubernetes u OpenShift.

Las API del Sail Operator se basan en las API del chart de Helm de Istio. Todas las opciones de instalación y configuración que exponen los charts de Helm de Istio están disponibles a través de los campos `values:` de la CRD del Sail Operator.

El Sail Operator no es compatible con el proyecto Istio.

## ¿Qué es un operador y por qué Istio tenía uno?

El [patrón de operador](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) fue popularizado por CoreOS en 2016 como un método para codificar la inteligencia humana en código. El caso de uso más común es un operador de base de datos, donde un usuario puede tener varias instancias de base de datos en un cluster, con múltiples tareas operativas en curso (copias de seguridad, vaciados, fragmentación).

Istio introdujo istioctl y el operador in-cluster en la versión 1.4, en respuesta a los problemas con Helm v2. Casi al mismo tiempo, se introdujo Helm v3, que abordó las preocupaciones de la comunidad y es un método preferido para instalar software en Kubernetes en la actualidad. El soporte para Helm v3 se agregó en Istio 1.8.

El operador in-cluster de Istio se encargaba de la instalación de los componentes de la service mesh, una operación que generalmente se realiza una vez y para una instancia por cluster. Puedes pensar en ello como una forma de ejecutar istioctl dentro de tu cluster. Sin embargo, esto significaba que tenías un controlador de altos privilegios ejecutándose dentro de tu cluster, lo que debilita tu postura de seguridad. No se encarga de ninguna tarea de administración continua (las copias de seguridad, la toma de instantáneas, etc., no son requisitos para ejecutar Istio).

El operador de Istio es algo que tienes que instalar en el cluster, lo que significa que ya tienes que gestionar la instalación de algo. Usarlo para actualizar el cluster también requería primero que descargaras y ejecutaras una nueva versión de istioctl.

Usar un operador significa que has creado un nivel de indirección, donde tienes que tener opciones en tu recurso personalizado para configurar todo lo que desees cambiar en una instalación. Istio solucionó esto ofreciendo la API `IstioOperator`, que permite la configuración de las opciones de instalación. Este recurso es utilizado tanto por el operador in-cluster como por la instalación de istioctl, por lo que existe una ruta de migración trivial para los usuarios del operador.

Hace tres años, alrededor de la época de Istio 1.12, actualizamos nuestra documentación para decir que se desaconseja el uso del operador para nuevas instalaciones de Istio, y que los usuarios deberían usar istioctl o Helm para instalar Istio.

[Tener tres métodos de instalación diferentes ha causado confusión](https://blog.howardjohn.info/posts/istio-install/), y para proporcionar la mejor experiencia a las personas que usan Helm o istioctl, más del 90% de nuestra base de instalación, hemos decidido desaprobar formalmente el operador in-cluster en Istio 1.23.
