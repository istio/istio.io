---
title: Configurar istioctl para un clúster remoto
description: Usar un servidor proxy para soportar comandos de istioctl en un mesh con un control plane externo.
publishdate: 2022-03-25
attribution: Frank Budinsky (IBM)
keywords: [istioctl, cli, external, remote, multicluster]
---

Al usar la CLI `istioctl` en un {{< gloss >}}remote cluster{{< /gloss >}} de un despliegue de Istio con
[control plane externo](/docs/setup/install/external-controlplane/) o [multiclúster](/docs/setup/install/multicluster/),
algunos comandos no funcionarán por defecto. Por ejemplo, `istioctl proxy-status` requiere acceso al servicio `istiod` para
obtener el estado y la configuración de los proxies que gestiona. Si intentas ejecutarlo en un clúster remoto, obtendrás un
mensaje de error como este:

{{< text bash >}}
$ istioctl proxy-status
Error: unable to find any Istiod instances
{{< /text >}}

Observa que el mensaje de error no solo dice que no puede acceder al servicio `istiod`; menciona específicamente que no puede
encontrar instancias de `istiod`. Esto se debe a que la implementación de `istioctl proxy-status` necesita recuperar el estado
de sincronización no de una sola instancia de `istiod`, sino de todas. Cuando hay más de una instancia (réplica) de `istiod`
ejecutándose, cada instancia solo está conectada a un subconjunto de los proxies de servicio que se ejecutan en el mesh.
El comando `istioctl` necesita devolver el estado de todo el mesh, no solo del subconjunto gestionado por una de las instancias.

En una instalación “normal” de Istio en la que el servicio `istiod` se ejecuta localmente en el clúster
(es decir, un {{< gloss >}}primary cluster{{< /gloss >}}), el comando se implementa encontrando todos los pods `istiod` en ejecución,
llamando a cada uno por turnos y agregando el resultado antes de devolvérselo al usuario.

{{< image width="75%"
    link="istioctl-primary-cluster.svg"
    caption="CLI con acceso local a los pods de istiod"
    >}}

En un clúster remoto, por el contrario, esto no es posible porque las instancias de `istiod` se ejecutan fuera del clúster del mesh
y no son accesibles para el usuario del mesh. Incluso puede que esas instancias no estén desplegadas como pods en un clúster Kubernetes.

Por suerte, `istioctl` ofrece una opción de configuración para abordar este problema.
Puedes configurar `istioctl` con la dirección de un servicio proxy externo que sí tenga acceso a las instancias de `istiod`.
A diferencia de un servicio balanceador normal, que delegaría las peticiones entrantes a una de las instancias, este servicio proxy debe
delegar en todas las instancias de `istiod`, agregar las respuestas y devolver el resultado combinado.

Si el servicio proxy externo se está ejecutando en otro clúster Kubernetes, el código de implementación del proxy puede ser muy similar
al código que ejecuta `istioctl` en el caso de clúster primario: encontrar todos los pods `istiod` en ejecución, llamar a cada uno
por turnos y agregar el resultado.

{{< image width="75%"
    link="istioctl-remote-cluster.svg"
    caption="CLI sin acceso local a los pods de istiod"
    >}}

Puedes encontrar un proyecto del ecosistema de Istio que incluye una implementación de este servidor proxy de `istioctl`
[aquí](https://github.com/istio-ecosystem/istioctl-proxy-sample). Para probarlo, necesitarás dos clústeres, uno de los cuales esté
configurado como clúster remoto usando un control plane instalado en el otro clúster.

## Instalar Istio con una topología de clúster remoto

Para demostrar que `istioctl` funciona en un clúster remoto, comenzaremos usando las
[instrucciones de instalación de control plane externo](/docs/setup/install/external-controlplane/)
para configurar un mesh con un único clúster remoto y un control plane externo ejecutándose en un clúster externo separado.

Tras completar la instalación, deberíamos tener dos variables de entorno, `CTX_REMOTE_CLUSTER` y `CTX_EXTERNAL_CLUSTER`,
que contienen los nombres de contexto del clúster remoto (mesh) y del clúster externo (control plane), respectivamente.

También deberíamos tener los ejemplos `helloworld` y `sleep` ejecutándose en el mesh, es decir, en el clúster remoto:

{{< text bash >}}
$ kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-776f57d5f6-tmpkd   2/2     Running   0          10s
sleep-557747455f-v627d           2/2     Running   0          9s
{{< /text >}}

Observa que si intentas ejecutar `istioctl proxy-status` en el clúster remoto, verás el mensaje de error descrito anteriormente:

{{< text bash >}}
$ istioctl proxy-status --context="${CTX_REMOTE_CLUSTER}"
Error: unable to find any Istiod instances
{{< /text >}}

## Configurar istioctl para usar el servicio proxy de ejemplo

Para configurar `istioctl`, primero necesitamos desplegar el servicio proxy junto a los pods `istiod` en ejecución.
En nuestra instalación, hemos desplegado el control plane en el namespace `external-istiod`, así que iniciamos el servicio proxy
en el clúster externo con el siguiente comando:

{{< text bash >}}
$ kubectl apply -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}" \
    -f https://raw.githubusercontent.com/istio-ecosystem/istioctl-proxy-sample/main/istioctl-proxy.yaml
service/istioctl-proxy created
serviceaccount/istioctl-proxy created
secret/jwt-cert-key-secret created
deployment.apps/istioctl-proxy created
role.rbac.authorization.k8s.io/istioctl-proxy-role created
rolebinding.rbac.authorization.k8s.io/istioctl-proxy-role created
{{< /text >}}

Puedes ejecutar el siguiente comando para confirmar que el servicio `istioctl-proxy` se está ejecutando junto a `istiod`:

{{< text bash >}}
$ kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
NAME                              READY   STATUS    RESTARTS   AGE
istioctl-proxy-664bcc596f-9q8px   1/1     Running   0          15s
istiod-666fb6694d-jklkt           1/1     Running   0          5m31s
{{< /text >}}

El servicio proxy es un servidor gRPC que sirve en el puerto 9090:

{{< text bash >}}
$ kubectl get svc istioctl-proxy -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
istioctl-proxy   ClusterIP   172.21.127.192   <none>        9090/TCP   11m
{{< /text >}}

Antes de poder usarlo, sin embargo, necesitamos exponerlo fuera del clúster externo.
Hay muchas formas de hacerlo, según el entorno de despliegue. En nuestro setup, tenemos un ingress gateway ejecutándose en el clúster externo,
así que podríamos actualizarlo para exponer también el puerto 9090, actualizar el virtual service asociado para dirigir las peticiones del puerto 9090
al servicio proxy, y después configurar `istioctl` para usar la dirección del gateway como dirección del proxy. Este sería el enfoque “correcto”.

Sin embargo, como esta es solo una demostración simple en la que tenemos acceso a ambos clústeres, haremos simplemente `port-forward`
del servicio proxy a `localhost`:

{{< text bash >}}
$ kubectl port-forward -n external-istiod service/istioctl-proxy 9090:9090 --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

Ahora configuramos `istioctl` para usar `localhost:9090` y acceder al proxy estableciendo la variable de entorno `ISTIOCTL_XDS_ADDRESS`:

{{< text bash >}}
$ export ISTIOCTL_XDS_ADDRESS=localhost:9090
$ export ISTIOCTL_ISTIONAMESPACE=external-istiod
$ export ISTIOCTL_PREFER_EXPERIMENTAL=true
{{< /text >}}

Como nuestro control plane se está ejecutando en el namespace `external-istiod`, en lugar del `istio-system` por defecto, también
necesitamos establecer la variable de entorno `ISTIOCTL_ISTIONAMESPACE`.

Establecer `ISTIOCTL_PREFER_EXPERIMENTAL` es opcional. Indica a `istioctl` que redirija llamadas `istioctl comando` a su equivalente experimental,
`istioctl x comando`, para cualquier `comando` que tenga implementación estable y experimental.
En nuestro caso, necesitamos usar `istioctl x proxy-status`, la versión que implementa la funcionalidad de delegación a un proxy.

## Ejecutar el comando istioctl proxy-status

Ahora que hemos terminado de configurar `istioctl`, podemos probarlo ejecutando de nuevo el comando `proxy-status`:

{{< text bash >}}
$ istioctl proxy-status --context="${CTX_REMOTE_CLUSTER}"
NAME                                                      CDS        LDS        EDS        RDS        ISTIOD         VERSION
helloworld-v1-776f57d5f6-tmpkd.sample                     SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
istio-ingressgateway-75bfd5668f-lggn4.external-istiod     SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
sleep-557747455f-v627d.sample                             SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
{{< /text >}}

Como puedes ver, esta vez muestra correctamente el estado de sincronización de todos los servicios que se ejecutan en el mesh. Observa que la columna
`ISTIOD` devuelve el valor genérico `<external>`, en lugar del nombre de la instancia (por ejemplo, `istiod-666fb6694d-jklkt`) que se mostraría si el pod
se ejecutara localmente. En este caso, este detalle no está disponible (ni es necesario) para el usuario del mesh. Solo está disponible en el clúster externo
para que lo vea el operador del mesh.

## Resumen

En este artículo usamos un [servidor proxy de ejemplo](https://github.com/istio-ecosystem/istioctl-proxy-sample) para configurar `istioctl` y que funcione
con una [instalación de control plane externo](/docs/setup/install/external-controlplane/).
Hemos visto que algunos comandos de la CLI `istioctl` no funcionan “out of the box” en un clúster remoto gestionado por un control plane externo. Comandos
como `istioctl proxy-status`, entre otros, necesitan acceso a las instancias del servicio `istiod` que gestionan el mesh, las cuales no están disponibles cuando
el control plane se ejecuta fuera del clúster del mesh.
Para abordar este problema, `istioctl` se configuró para delegar en un servidor proxy, ejecutándose junto al control plane externo, que accede a las instancias
de `istiod` en su nombre.
