---
title: Verificar la instalación ambient
description: Verifica que la mesh ambient de Istio se ha instalado correctamente en múltiples clústeres.
weight: 50
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/multi-primary_multi-network
---

Sigue esta guía para verificar que tu instalación multiclúster de Istio en modo ambient está
funcionando correctamente.

Antes de proceder, asegúrate de completar los pasos en
[antes de comenzar](/docs/ambient/install/multicluster/before-you-begin) así como
elegir y seguir una de las [guías de instalación multiclúster](/docs/ambient/install/multicluster).

En esta guía, verificaremos que el multiclúster es funcional, desplegaremos la aplicación `HelloWorld`
`v1` en `cluster1` y `v2` en `cluster2`. Al recibir un request,
`HelloWorld` incluirá su versión en su respuesta cuando llamemos al path `/hello`.

También desplegaremos el contenedor `curl` en ambos clústeres. Usaremos estos
pods como fuente de requests al servicio `HelloWorld`,
simulando tráfico dentro de la mesh. Finalmente, después de generar tráfico, observaremos
qué clúster recibió los requests.

## Verificar el multiclúster

Para confirmar que Istiod ahora puede comunicarse con el control plane de Kubernetes
del clúster remoto.

{{< text bash >}}
$ istioctl remote-clusters --context="${CTX_CLUSTER1}"
NAME         SECRET                                        STATUS      ISTIOD
cluster1                                                   synced      istiod-7b74b769db-kb4kj
cluster2     istio-system/istio-remote-secret-cluster2     synced      istiod-7b74b769db-kb4kj
{{< /text >}}

Todos los clústeres deberían indicar su estado como `synced`. Si un clúster está listado con
un `STATUS` de `timeout` significa que Istiod en el clúster primario no puede
comunicarse con el clúster remoto. Consulta los logs de Istiod para mensajes de error detallados.

Nota: si ves problemas de `timeout` y hay un host intermediario (como el [proxy de autenticación de Rancher](https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/manage-clusters/access-clusters/authorized-cluster-endpoint#two-authentication-methods-for-rke-clusters))
entre Istiod en el clúster primario y el control plane de Kubernetes en
el clúster remoto, es posible que debas actualizar el campo `certificate-authority-data`
del kubeconfig que genera `istioctl create-remote-secret` para que
coincida con el certificado que usa el host intermediario.

## Desplegar el servicio `HelloWorld`

Para que el servicio `HelloWorld` sea accesible desde cualquier clúster, la búsqueda DNS
debe tener éxito en cada clúster (consulta
[modelos de despliegue](/docs/ops/deployment/deployment-models#dns-with-multiple-clusters)
para más detalles). Lo abordaremos desplegando el servicio `HelloWorld` en
cada clúster de la mesh.

{{< tip >}}
Antes de proceder, asegúrate de que los namespaces istio-system en ambos clústeres tengan `istio.io/topology-network` configurado con el valor apropiado (por ejemplo, `network1` para `cluster1` y `network2` para `cluster2`).
{{< /tip >}}

Para comenzar, crea el namespace `sample` en cada clúster:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace sample
{{< /text >}}

Incorpora el namespace `sample` a la mesh:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio.io/dataplane-mode=ambient
$ kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio.io/dataplane-mode=ambient
{{< /text >}}

Crea el servicio `HelloWorld` en ambos clústeres:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
{{< /text >}}

## Desplegar `HelloWorld` `V1`

Despliega la aplicación `helloworld-v1` en `cluster1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v1 -n sample
{{< /text >}}

Confirma el estado del pod `helloworld-v1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  1/1       Running   0          40s
{{< /text >}}

Espera hasta que el estado de `helloworld-v1` sea `Running`.

Ahora, marca el servicio helloworld en `cluster1` como global para que pueda accederse desde otros clústeres de la mesh:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## Desplegar `HelloWorld` `V2`

Despliega la aplicación `helloworld-v2` en `cluster2`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v2 -n sample
{{< /text >}}

Confirma el estado del pod `helloworld-v2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  1/1       Running   0          40s
{{< /text >}}

Espera hasta que el estado de `helloworld-v2` sea `Running`.

Ahora, marca el servicio helloworld en `cluster2` como global para que pueda accederse desde otros clústeres de la mesh:

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER2}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## Desplegar `curl`

Despliega la aplicación `curl` en ambos clústeres:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/curl/curl.yaml@ -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/curl/curl.yaml@ -n sample
{{< /text >}}

Confirma el estado del pod `curl` en `cluster1`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-n6bzf            1/1     Running   0          5s
{{< /text >}}

Espera hasta que el estado del pod `curl` sea `Running`.

Confirma el estado del pod `curl` en `cluster2`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-dzl9j            1/1     Running   0          5s
{{< /text >}}

Espera hasta que el estado del pod `curl` sea `Running`.

## Verificar el tráfico entre clústeres

Para verificar que el balanceo de carga entre clústeres funciona como se espera, llama al
servicio `HelloWorld` varias veces usando el pod `curl`. Para asegurar que el balanceo
de carga funciona correctamente, llama al servicio `HelloWorld` desde todos
los clústeres en tu despliegue.

Envía un request desde el pod `curl` en `cluster1` al servicio `HelloWorld`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Repite este request varias veces y verifica que la versión de `HelloWorld`
debe cambiar entre `v1` y `v2`, lo que indica que se están usando endpoints en ambos
clústeres:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Ahora repite este proceso desde el pod `curl` en `cluster2`:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Repite este request varias veces y verifica que la versión de `HelloWorld`
debe alternar entre `v1` y `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**¡Felicitaciones!** Instalaste y verificaste exitosamente Istio en múltiples
clústeres.

## Próximos pasos

Configura el [failover por localidad](/docs/ambient/install/multicluster/failover) para tu despliegue multiclúster.

Despliega [Kiali](/docs/ambient/install/multicluster/observability) para tu despliegue multiclúster.
