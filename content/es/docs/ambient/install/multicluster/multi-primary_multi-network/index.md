---
title: Instalar ambient multi-primary en redes diferentes
description: Instala una mesh ambient de Istio en múltiples clústeres primarios en redes diferentes.
weight: 30
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
next: /docs/ambient/install/multicluster/verify
prev: /docs/ambient/install/multicluster/before-you-begin
---

{{< tip >}}
Esta guía requiere la instalación de los CRDs de la Gateway API.
{{< boilerplate gateway-api-install-crds >}}
{{< /tip >}}

Sigue esta guía para instalar el control plane de Istio tanto en `cluster1` como en
`cluster2`, haciendo que cada uno sea un {{< gloss >}}primary cluster{{< /gloss >}} (esta es actualmente la única configuración soportada en modo ambient). El clúster
`cluster1` está en la red `network1`, mientras que `cluster2` está en la
red `network2`. Esto significa que no hay conectividad directa entre pods
a través de los límites del clúster.

Antes de proceder, asegúrate de completar los pasos en
[antes de comenzar](/docs/ambient/install/multicluster/before-you-begin).

{{< boilerplate multi-cluster-with-metallb >}}

En esta configuración, tanto `cluster1` como `cluster2` observan los API Servers
en cada clúster para obtener endpoints.

Los workloads de servicio a través de los límites del clúster se comunican indirectamente, a través de
gateways dedicados para el tráfico [east-west](https://en.wikipedia.org/wiki/East-west_traffic).
El gateway en cada clúster debe ser accesible desde el otro clúster.

{{< image width="75%"
    link="arch.svg"
    caption="Múltiples clústeres primarios en redes separadas"
    >}}

## Establecer la red predeterminada para `cluster1`

Si el namespace istio-system ya fue creado, necesitamos establecer la red del clúster ahí:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## Configurar `cluster1` como primario

Crea la configuración de `istioctl` para `cluster1`:

{{< tabset category-name="multicluster-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Instala Istio como primario en `cluster1` usando istioctl y la API `IstioOperator`.

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
          - name: AMBIENT_ENABLE_BAGGAGE
            value: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
{{< /text >}}

Aplica la configuración a `cluster1`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Instala Istio como primario en `cluster1` usando los siguientes comandos de Helm:

Instala el chart `base` en `cluster1`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Luego, instala el chart `istiod` en `cluster1` con las siguientes configuraciones multiclúster:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true" --set env.AMBIENT_ENABLE_BAGGAGE="true"
{{< /text >}}

A continuación, instala el agente de nodo CNI en modo ambient:

{{< text syntax=bash snip_id=install_cni_cluster1 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER1}" --set profile=ambient
{{< /text >}}

Finalmente, instala el data plane ztunnel:

{{< text syntax=bash snip_id=install_ztunnel_cluster1 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}" --set multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Instalar un gateway east-west en modo ambient en `cluster1`

Instala un gateway en `cluster1` dedicado al tráfico
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) en modo ambient. Ten en
cuenta que, dependiendo de tu entorno de Kubernetes, este gateway puede
desplegarse en el Internet público por defecto. Los sistemas en producción pueden
requerir restricciones de acceso adicionales (por ejemplo, mediante reglas de firewall) para prevenir
ataques externos. Consulta con tu proveedor de nube para ver qué opciones están
disponibles.

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 \
    --ambient | \
    kubectl --context="${CTX_CLUSTER1}" apply -f -
{{< /text >}}

{{< warning >}}
Si el control plane se instaló con una revisión, agrega el flag `--revision rev` al comando `gen-eastwest-gateway.sh`.
{{< /warning >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

Instala el gateway east-west en `cluster1` usando la siguiente definición de Gateway:

{{< text bash >}}
$ cat <<EOF > cluster1-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network1"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # representa double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
Si estás ejecutando una instancia revisada de istiod y no tienes una revisión o etiqueta por defecto configurada, es posible que debas agregar la etiqueta `istio.io/rev` a este manifiesto de `Gateway`.
{{< /warning >}}

Aplica la configuración a `cluster1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -f cluster1-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Espera a que el gateway east-west reciba una dirección IP externa:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## Establecer la red predeterminada para `cluster2`

Si el namespace istio-system ya fue creado, necesitamos establecer la red del clúster ahí:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## Configurar cluster2 como primario

Crea la configuración de `istioctl` para `cluster2`:

{{< tabset category-name="multicluster-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Instala Istio como primario en `cluster2` usando istioctl y la API `IstioOperator`.

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
          - name: AMBIENT_ENABLE_BAGGAGE
            value: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
EOF
{{< /text >}}

Aplica la configuración a `cluster2`:

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Instala Istio como primario en `cluster2` usando los siguientes comandos de Helm:

Instala el chart `base` en `cluster2`:

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Luego, instala el chart `istiod` en `cluster2` con las siguientes configuraciones multiclúster:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network2 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true" --set env.AMBIENT_ENABLE_BAGGAGE="true"
{{< /text >}}

A continuación, instala el agente de nodo CNI en modo ambient:

{{< text syntax=bash snip_id=install_cni_cluster2 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER2}" --set profile=ambient
{{< /text >}}

Finalmente, instala el data plane ztunnel:

{{< text syntax=bash snip_id=install_ztunnel_cluster2 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"  --set multiCluster.clusterName=cluster2 --set global.network=network2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Instalar un gateway east-west en modo ambient en `cluster2`

Como hicimos con `cluster1` anteriormente, instala un gateway en `cluster2` dedicado
al tráfico east-west.

{{< tabset category-name="east-west-gateway-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 \
    --ambient | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
{{< /text >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

Instala el gateway east-west en `cluster2` usando la siguiente definición de Gateway:

{{< text bash >}}
$ cat <<EOF > cluster2-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network2"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # representa double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
Si estás ejecutando una instancia revisada de istiod y no tienes una revisión o etiqueta por defecto configurada, es posible que debas agregar la etiqueta `istio.io/rev` a este manifiesto de `Gateway`.
{{< /warning >}}

Aplica la configuración a `cluster2`:

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" -f cluster2-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Espera a que el gateway east-west reciba una dirección IP externa:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## Habilitar el descubrimiento de endpoints

Instala un secreto remoto en `cluster2` que proporcione acceso al API Server de `cluster1`.

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

Instala un secreto remoto en `cluster1` que proporcione acceso al API Server de `cluster2`.

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**¡Felicitaciones!** Instalaste exitosamente una mesh de Istio en múltiples
clústeres primarios en redes diferentes.

## Próximos pasos

Ahora puedes [verificar la instalación](/docs/ambient/install/multicluster/verify).

## Limpieza

Desinstala Istio de ambos `cluster1` y `cluster2` usando el mismo mecanismo con el que instalaste Istio (istioctl o Helm).

{{< tabset category-name="multicluster-uninstall-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Desinstala Istio en `cluster1`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Desinstala Istio en `cluster2`:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

Elimina la instalación de Helm de Istio de `cluster1`:

{{< text syntax=bash >}}
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

Elimina el namespace `istio-system` de `cluster1`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

Elimina la instalación de Helm de Istio de `cluster2`:

{{< text syntax=bash >}}
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

Elimina el namespace `istio-system` de `cluster2`:

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

(Opcional) Elimina los CRDs instalados por Istio:

Eliminar CRDs elimina permanentemente cualquier recurso de Istio que hayas creado en tus clústeres.
Para eliminar los CRDs de Istio instalados en tus clústeres:

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

Y finalmente, limpia los CRDs de la Gateway API:

{{< text syntax=bash snip_id=delete_gateway_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
