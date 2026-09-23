---
title: Prerrequisitos específicos de la plataforma
description: Prerrequisitos específicos de la plataforma para instalar Istio en modo ambient.
weight: 2
aliases:
  - /docs/ops/ambient/install/platform-prerequisites
  - /latest/docs/ops/ambient/install/platform-prerequisites
owner: istio/wg-environments-maintainers
test: no
---

Este documento cubre cualquier prerrequisito específico de la plataforma o del entorno para instalar Istio en modo ambient.

## Plataforma

Ciertos entornos de Kubernetes requieren que establezcas varias opciones de configuración de Istio para admitirlos.

### Google Kubernetes Engine (GKE)

#### Restricciones de namespaces

En GKE, cualquier pod con la `priorityClassName` [system-node-critical](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) solo se puede instalar en namespaces que tengan definida una [ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/). De forma predeterminada en GKE, solo `kube-system` tiene una ResourceQuota definida para la clase `node-critical`. El agente de nodo CNI de Istio y `ztunnel` requieren la clase `node-critical`, por lo que en GKE, ambos componentes deben:

- Instalarse en `kube-system` (_no_ en `istio-system`)
- Instalarse en otro namespaces (como `istio-system`) en el que se haya creado manualmente una ResourceQuota, por ejemplo:

{{< text syntax=yaml >}}
apiVersion: v1
kind: ResourceQuota
metadata:
  name: gcp-critical-pods
  namespace: istio-system
spec:
  hard:
    pods: 1000
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values:
      - system-node-critical
{{< /text >}}

#### Perfil de plataforma

Cuando uses GKE, debes agregar el valor de `platform` correcto a tus comandos de instalación, ya que GKE usa ubicaciones no estándar para los binarios de CNI, lo que requiere anulaciones de Helm.

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=gke --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=gke
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Amazon Elastic Kubernetes Service (EKS)

Si estás usando EKS:

- con el CNI de VPC de Amazon
- con el enlace de ENI de pod habilitado
- **y** estás usando SecurityGroups adjuntos a pods de EKS a través de [SecurityGroupPolicy](https://aws.github.io/aws-eks-best-practices/networking/sgpp/#enforcing-mode-use-strict-mode-for-isolating-pod-and-node-traffic)

[`POD_SECURITY_GROUP_ENFORCING_MODE` debe establecerse explícitamente en `standard`](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/README.md#pod_security_group_enforcing_mode-v1110), o las sondas de salud del pod fallarán. Esto se debe a que Istio usa una dirección SNAT de enlace local para identificar las sondas de salud de kubelet, y el CNI de VPC actualmente enruta incorrectamente los paquetes de enlace local en el modo `strict` de Pod Security Group. Agregar explícitamente una exclusión de CIDR para la dirección de enlace local a tu SecurityGroup no funcionará, porque el modo de Pod Security Group del CNI de VPC funciona enrutando silenciosamente el tráfico a través de enlaces, haciéndolos pasar por el `ENI de pod` troncal para la aplicación de la política de SecurityGroup. Dado que [el tráfico de enlace local no se puede enrutar a través de enlaces](https://datatracker.ietf.org/doc/html/rfc3927#section-2.6.2), la característica de Pod Security Group no puede aplicar políticas contra ellos como una restricción de diseño y descarta los paquetes en modo `strict`.

Hay un [problema abierto en el componente CNI de VPC](https://github.com/aws/amazon-vpc-cni-k8s/issues/2797) para esta limitación. La recomendación actual del equipo de CNI de VPC es deshabilitar el modo `strict` para solucionarlo, si estás usando Pod Security Groups, o usar sondas de Kubernetes basadas en `exec` para tus pods en lugar de las basadas en kubelet.

Puedes verificar si tienes habilitado el enlace de ENI de pod ejecutando el siguiente comando:

{{< text syntax=bash >}}
$ kubectl set env daemonset aws-node -n kube-system --list | grep ENABLE_POD_ENI
{{< /text >}}

Puedes verificar si tienes algún grupo de seguridad adjunto a un pod en tu cluster ejecutando el siguiente comando:

{{< text syntax=bash >}}
$ kubectl get securitygrouppolicies.vpcresources.k8s.aws
{{< /text >}}

Puedes establecer `POD_SECURITY_GROUP_ENFORCING_MODE=standard` ejecutando el siguiente comando y reciclando los pods afectados:

{{< text syntax=bash >}}
$ kubectl set env daemonset aws-node -n kube-system POD_SECURITY_GROUP_ENFORCING_MODE=standard
{{< /text >}}

### k3d

Cuando uses [k3d](https://k3d.io/) con el CNI de Flannel predeterminado, debes agregar el valor de `platform` correcto a tus comandos de instalación, ya que k3d usa ubicaciones no estándar para la configuración y los binarios de CNI, lo que requiere algunas anulaciones de Helm.

1. Crea un cluster con Traefik deshabilitado para que no entre en conflicto con las gateways de entrada de Istio:

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1.  Establece `global.platform=k3d` al instalar los charts de Istio. Por ejemplo:

    {{< tabset category-name="install-method" >}}

    {{< tab name="Helm" category-value="helm" >}}

        {{< text syntax=bash >}}
        $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3d --wait
        {{< /text >}}

    {{< /tab >}}

    {{< tab name="istioctl" category-value="istioctl" >}}

        {{< text syntax=bash >}}
        $ istioctl install --set profile=ambient --set values.global.platform=k3d
        {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

### K3s

Cuando uses [K3s](https://k3s.io/) y uno de sus CNI incluidos, debes agregar el valor de `platform` correcto a tus comandos de instalación, ya que K3s usa ubicaciones no estándar para la configuración y los binarios de CNI, lo que requiere algunas anulaciones de Helm. Para las rutas predeterminadas de K3s, Istio proporciona anulaciones integradas basadas en el valor `global.platform`.

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3s --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=k3s
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Sin embargo, estas ubicaciones se pueden anular en K3s, [según la documentación de K3s](https://docs.k3s.io/cli/server#k3s-server-cli-help). Si estás usando K3s con un CNI personalizado no incluido, debes especificar manualmente las rutas correctas para esos CNI, por ejemplo, `/etc/cni/net.d`; [consulta la documentación de K3s para obtener más detalles](https://docs.k3s.io/networking/basic-network-options#custom-cni). Por ejemplo:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set cniBinDir=/var/lib/rancher/k3s/data/current/bin/
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/current/bin/
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### MicroK8s

Si estás instalando Istio en [MicroK8s](https://microk8s.io/), debes agregar el valor de `platform` correcto a tus comandos de instalación, ya que MicroK8s [usa ubicaciones no estándar para la configuración y los binarios de CNI](https://microk8s.io/docs/change-cidr). Por ejemplo:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=microk8s --wait

    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=microk8s
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### minikube

Si estás usando [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) con el [controlador de Docker](https://minikube.sigs.k8s.io/docs/drivers/docker/),
debes agregar el valor de `platform` correcto a tus comandos de instalación, ya que minikube con Docker usa una ruta de montaje de enlace no estándar para los contenedores.
Por ejemplo:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=minikube --wait"
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=minikube"
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Red Hat OpenShift

OpenShift requiere que los componentes `ztunnel` e `istio-cni` se instalen enel namespace `kube-system`, y que establezcas `global.platform=openshift` para todos los charts.

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    Debes `--set global.platform=openshift` para **cada** chart que instales, por ejemplo, con el chart `istiod`:

    {{< text syntax=bash >}}
    $ helm install istiod istio/istiod -n istio-system --set profile=ambient --set global.platform=openshift --wait
    {{< /text >}}

    Además, debes instalar `istio-cni` y `ztunnel` enel namespace `kube-system`, por ejemplo:

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n kube-system --set profile=ambient --set global.platform=openshift --wait
    $ helm install ztunnel istio/ztunnel -n kube-system --set profile=ambient --set global.platform=openshift --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=openshift-ambient --skip-confirmation
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Complementos de CNI

Las siguientes configuraciones se aplican a todas las plataformas, cuando se utilizan ciertos complementos de {{< gloss "CNI" >}}CNI{{< /gloss >}}:

### Cilium

1. Cilium actualmente tiene como valor predeterminado eliminar proactivamente otros complementos de CNI y su configuración, y debe configurarse con
`cni.exclusive = false` para admitir correctamente el encadenamiento. Consulta [la documentación de Cilium](https://docs.cilium.io/en/stable/helm-reference/) para obtener más detalles.
1. El enmascaramiento BPF de Cilium está actualmente deshabilitado de forma predeterminada y tiene problemas con el uso de Istio de IP de enlace local para la verificación de estado de Kubernetes. Habilitar el enmascaramiento BPF a través de `bpf.masquerade=true` no es compatible actualmente y da como resultado verificaciones de estado de pod no funcionales en Istio ambient. La implementación de enmascaramiento de iptables predeterminada de Cilium debería seguir funcionando correctamente.
1. Debido a cómo Cilium administra la identidad del nodo e internamente permite las sondas de estado a nivel de nodo a los pods,
aplicar cualquier `NetworkPolicy` de DENEGACIÓN predeterminada en una instalación de Cilium CNI subyacente a Istio en modo ambient hará que las sondas de estado de `kubelet` (que por defecto están exentas silenciosamente de toda aplicación de políticas por parte de Cilium) se bloqueen. Esto se debe a que Istio usa una dirección SNAT de enlace local para las sondas de estado de kubelet, de la que Cilium no tiene conocimiento, y Cilium no tiene una opción para eximir las direcciones de enlace local de la aplicación de políticas.

    Esto se puede resolver aplicando la siguiente `CiliumClusterWideNetworkPolicy`:

    {{< text syntax=yaml >}}
    apiVersion: "cilium.io/v2"
    kind: CiliumClusterwideNetworkPolicy
    metadata:
      name: "allow-ambient-hostprobes"
    spec:
      description: "Permite que las sondas de verificación de estado de kubelet con SNAT ingresen a los pods ambient"
      enableDefaultDeny:
        egress: false
        ingress: false
      endpointSelector: {}
      ingress:
      - fromCIDR:
        - "169.254.7.127/32"
    {{< /text >}}

    Esta anulación de política *no* es necesaria a menos que ya tengas otras `NetworkPolicies` o `CiliumNetworkPolicies` de denegación predeterminada aplicadas en tu cluster.

    Consulta [el problema #49277](https://github.com/istio/istio/issues/49277) y [CiliumClusterWideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy) para obtener más detalles.
