---
title: Sidecars nativos de Kubernetes en Istio
description: Demostrando la nueva característica de SidecarContainers con Istio.
publishdate: 2023-08-15
attribution: "John Howard (Google)"
keywords: [istio,sidecars,kubernetes]
---

Si has escuchado algo sobre service meshes, es que funcionan usando el patrón sidecar: un servidor proxy se implementa junto al código de tu aplicación.
El patrón sidecar es solo eso: un patrón.
Hasta este punto, no ha habido soporte formal para contenedores sidecar en Kubernetes en absoluto.

Esto ha causado una serie de problemas: ¿qué pasa si tienes un trabajo que termina por diseño, pero un contenedor sidecar que no lo hace?
Este caso de uso exacto es el [más popular jamás en el rastreador de issues de Kubernetes](https://github.com/kubernetes/kubernetes/issues/25908).

Una propuesta formal para agregar soporte de sidecar en Kubernetes se planteó en 2019. Con muchas paradas y arranques en el camino,
y después de un reinicio del proyecto el año pasado, el soporte formal para sidecars se está lanzando a Alpha en Kubernetes 1.28.
Istio ha implementado soporte para esta característica, y en esta publicación puedes aprender cómo aprovecharlo.

## Problemas de sidecar

Los contenedores sidecar dan mucho poder, pero vienen con algunos problemas.
Mientras que los contenedores dentro de un pod pueden compartir algunas cosas, sus *ciclos de vida* están completamente desacoplados.
Para Kubernetes, ambos contenedores son funcionalmente iguales.

Sin embargo, en Istio no son iguales - el contenedor de Istio es requerido para que el contenedor de aplicación principal funcione,
y no tiene valor sin el contenedor de aplicación principal.

Esta discrepancia en expectativas lleva a una variedad de problemas:
* Si el contenedor de aplicación arranca más rápido que el contenedor de Istio, no puede acceder a la red.
  Esto gana el [mayor número de +1s](https://github.com/istio/istio/issues/11130) en el GitHub de Istio por un amplio margen.
* Si el contenedor de Istio se apaga antes que el contenedor de aplicación, el contenedor de aplicación no puede acceder a la red.
* Si un contenedor de aplicación sale intencionalmente (típicamente por uso en un `Job`), el contenedor de Istio aún se ejecutará y mantendrá el pod ejecutándose indefinidamente.
  Esto también es un [issue top en GitHub](https://github.com/istio/istio/issues/11659).
* `InitContainers`, que se ejecutan antes de que comience el contenedor de Istio, no pueden acceder a la red.

Se han gastado innumerables horas en la comunidad de Istio y más allá para sortear estos problemas - con éxito limitado.

## Arreglando la causa raíz

Mientras que soluciones alternativas cada vez más complejas en Istio pueden ayudar a aliviar el dolor para los usuarios de Istio, idealmente todo esto simplemente funcionaría - y no solo para Istio.
Afortunadamente, la comunidad de Kubernetes ha estado trabajando duro para abordar estos directamente en Kubernetes.

En Kubernetes 1.28, se fusionó una nueva característica para agregar soporte nativo para sidecars, cerrando más de 5 años de trabajo continuo.
¡Con esto fusionado, todos nuestros problemas pueden ser abordados sin soluciones alternativas!

Mientras estamos en el "salón de la fama de issues de GitHub", [estos](https://github.com/kubernetes/kubernetes/issues/25908) dos [issues](https://github.com/kubernetes/kubernetes/issues/65502) representan los issues #1 y #6 de todos los tiempos en Kubernetes - ¡y finalmente han sido cerrados!

Un agradecimiento especial va para el enorme grupo de individuos involucrados en llevar esto más allá de la línea de meta.

## Probándolo

Aunque Kubernetes 1.28 acaba de ser lanzado, la nueva característica `SidecarContainers` está en Alpha (y por lo tanto, desactivada por defecto), y el soporte para la característica en Istio aún no se ha enviado, aún podemos probarlo hoy - ¡solo no intentes esto en producción!

Primero, necesitamos crear un clúster Kubernetes 1.28, con la característica `SidecarContainers` habilitada:

{{< text shell >}}
$ cat <<EOF | kind create cluster --name sidecars --image gcr.io/istio-testing/kind-node:v1.28.0 --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  SidecarContainers: true
EOF
{{< /text >}}

Luego podemos descargar el último prelanzamiento de Istio 1.19 (ya que 1.19 aún no ha salido). Usé Linux aquí.
Este es un prelanzamiento de Istio, así que nuevamente - ¡no intentes esto en producción!
Cuando instalemos Istio, habilitaremos la bandera de característica para soporte de sidecar nativo y activaremos los logs de acceso para ayudar a demostrar las cosas más tarde.

{{< text shell >}}
$ TAG=1.19.0-beta.0
$ curl -L https://github.com/istio/istio/releases/download/$TAG/istio-$TAG-linux-amd64.tar.gz | tar xz
$ ./istioctl install --set values.pilot.env.ENABLE_NATIVE_SIDECARS=true -y --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

Y finalmente podemos implementar una carga de trabajo:

{{< text shell >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f samples/sleep/sleep.yaml
{{< /text >}}

Veamos el pod:

{{< text shell >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-7656cf8794-8fhdk   2/2     Running   0          51s
{{< /text >}}

Todo parece normal a primera vista...
Si miramos bajo el capó, sin embargo, podemos ver la magia.

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME                     INIT                     CONTAINERS
sleep-7656cf8794-8fhdk   istio-init,istio-proxy   sleep
{{< /text >}}

Aquí podemos ver todos los `containers` e `initContainers` en el pod.

¡Sorpresa! `istio-proxy` ahora es un `initContainer`.

Más específicamente, es un `initContainer` con `restartPolicy: Always` establecido (un nuevo campo, habilitado por la característica `SidecarContainers`).
Esto le dice a Kubernetes que lo trate como un sidecar.

Esto significa que los contenedores posteriores en la lista de `initContainers`, y todos los `containers` normales no comenzarán hasta que el contenedor proxy esté listo.
Además, el pod terminará incluso si el contenedor proxy todavía se está ejecutando.

### Tráfico de contenedores init

Para poner esto a prueba, hagamos que nuestro pod realmente haga algo.
Aquí implementamos un pod simple que envía una solicitud en un `initContainer`.
Normalmente, esto fallaría.

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: sleep
spec:
  initContainers:
  - name: check-traffic
    image: istio/base
    command:
    - curl
    - httpbin.org/get
  containers:
  - name: sleep
    image: istio/base
    command: ["/bin/sleep", "infinity"]
{{< /text >}}

Verificando el contenedor proxy, podemos ver que la solicitud tanto tuvo éxito como pasó por el sidecar de Istio:

{{< text shell >}}
$ kubectl logs sleep -c istio-proxy | tail -n1
[2023-07-25T22:00:45.703Z] "GET /get HTTP/1.1" 200 - via_upstream - "-" 0 1193 334 334 "-" "curl/7.81.0" "1854226d-41ec-445c-b542-9e43861b5331" "httpbin.org" ...
{{< /text >}}

Si inspeccionamos el pod, podemos ver que nuestro sidecar ahora se ejecuta *antes* del `initContainer` `check-traffic`:

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME    INIT                                  CONTAINERS
sleep   istio-init,istio-proxy,check-traffic   sleep
{{< /text >}}

### Pods que salen

Anteriormente, mencionamos que cuando las aplicaciones salen (común en `Jobs`), el pod viviría para siempre.
¡Afortunadamente, esto también está abordado!

Primero implementamos un pod que saldrá después de un segundo y no se reiniciará:

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: sleep
spec:
  restartPolicy: Never
  containers:
- name: sleep
  image: istio/base
  command: ["/bin/sleep", "1"]
{{< /text >}}

Y podemos observar su progreso:

{{< text shell >}}
$ kubectl get pods -w
NAME    READY   STATUS     RESTARTS   AGE
sleep   0/2     Init:1/2   0          2s
sleep   0/2     PodInitializing   0          2s
sleep   1/2     PodInitializing   0          3s
sleep   2/2     Running           0          4s
sleep   1/2     Completed         0          5s
sleep   0/2     Completed         0          12s
{{< /text >}}

Aquí podemos ver que el contenedor de aplicación salió, y poco después el contenedor sidecar de Istio también sale.
Anteriormente, el pod estaría atascado en `Running`, mientras que ahora puede transitar a `Completed`.
¡No más pods zombi!

## ¿Qué hay del modo ambient?

El año pasado, Istio anunció [modo ambient](/blog/2022/introducing-ambient-mesh/) - un nuevo modo de data plane para Istio que no depende de contenedores sidecar.
Entonces, con el modo ambient viniendo, ¿algo de esto importa?

¡Yo diría que un rotundo "Sí"!

Aunque los impactos del sidecar se reducen cuando se usa el modo ambient para una carga de trabajo, espero que casi todos los usuarios de Kubernetes a gran escala tengan algún tipo de sidecar en sus implementaciones.
Esto podría ser cargas de trabajo de Istio que no quieren migrar a ambient, que aún *no han* migrado, o cosas no relacionadas con Istio.
Así que aunque pueda haber menos escenarios donde esto importa, sigue siendo una gran mejora para los casos donde se usan sidecars.

Podrías preguntarte lo contrario - si todos nuestros problemas de sidecar están abordados, ¿por qué necesitamos el modo ambient en absoluto?
Todavía hay una variedad de beneficios que ambient trae con estas limitaciones de sidecar abordadas.
Por ejemplo, [esta publicación de blog](/blog/2023/waypoint-proxy-made-simple/) entra en detalles sobre por qué desacoplar proxies de las cargas de trabajo es ventajoso.

## Pruébalo tú mismo

¡Animamos a los lectores aventureros a probarlo ellos mismos en entornos de prueba!
Los comentarios para estas características experimentales y alpha son críticos para asegurar que sean estables y cumplan con las expectativas antes de promoverlas.
Si lo pruebas, ¡cuéntanos qué piensas en el [Istio Slack](/get-involved/)!

En particular, el equipo de Kubernetes está interesado en escuchar más sobre:

* Manejo de la secuencia de apagado, especialmente cuando hay múltiples sidecars involucrados.
* Manejo de reinicio de retroceso cuando los contenedores sidecar están fallando.
* Casos extremos que aún no han considerado.
