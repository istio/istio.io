---
title: Instalación de Virtual Machine
description: Despliega Istio y conecta a él un workload que se ejecuta dentro de una virtual machine.
weight: 60
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
owner: istio/wg-environments-maintainers
test: yes
---

Sigue esta guía para desplegar Istio y conectar una virtual machine a él.

## Prerrequisitos

1. [Descarga la versión de Istio](/es/docs/setup/additional-setup/download-istio-release/)
1. Realiza cualquier [configuración específica de la plataforma](/es/docs/setup/platform-setup/) que sea necesaria
1. Verifica los requisitos [para Pods y Services](/es/docs/ops/deployment/application-requirements/)
1. Las virtual machines deben tener conectividad IP con el ingress gateway de la mesh a la que se conectan y, opcionalmente, con cada pod de la mesh mediante redes L3 si se desea un mejor rendimiento.
1. Conoce la [arquitectura de Virtual Machine](/es/docs/ops/deployment/vm-architecture/) para entender la arquitectura de alto nivel de la integración de virtual machines de Istio.

## Preparar el entorno de la guía

1. Crea una virtual machine
1. Establece las variables de entorno `VM_APP`, `WORK_DIR`, `VM_NAMESPACE`
y `SERVICE_ACCOUNT` en la máquina que estás usando para configurar el clúster
    (por ejemplo, `WORK_DIR="${HOME}/vmintegration"`):

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Single-Network" category-value="single" >}}

    {{< text bash >}}
    $ VM_APP="<the name of the application this VM will run>"
    $ VM_NAMESPACE="<the name of your service namespace>"
    $ WORK_DIR="<a certificate working directory>"
    $ SERVICE_ACCOUNT="<name of the Kubernetes service account you want to use for your VM>"
    $ CLUSTER_NETWORK=""
    $ VM_NETWORK=""
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Multi-Network" category-value="multiple" >}}

    {{< text bash >}}
    $ VM_APP="<the name of the application this VM will run>"
    $ VM_NAMESPACE="<the name of your service namespace>"
    $ WORK_DIR="<a certificate working directory>"
    $ SERVICE_ACCOUNT="<name of the Kubernetes service account you want to use for your VM>"
    $ # Customize the network names as needed
    $ CLUSTER_NETWORK="kube-network"
    $ VM_NETWORK="vm-network"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Crea el directorio de trabajo en la máquina que estás usando para configurar el clúster:

    {{< text syntax=bash snip_id=setup_wd >}}
    $ mkdir -p "${WORK_DIR}"
    {{< /text >}}

## Instalar el control plane de Istio

Si tu clúster ya tiene un control plane de Istio, puedes omitir los pasos de instalación, pero aún necesitarás exponer el control plane para el acceso de la virtual machine.

Instala Istio y expón el control plane en el clúster para que tu virtual machine pueda acceder a él.

{{< tip >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

1. Crea la especificación de `IstioOperator` para la instalación.

    {{< text syntax="bash yaml" snip_id=setup_iop >}}
    $ cat <<EOF > ./vm-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      name: istio
    spec:
      values:
        global:
          network: "${CLUSTER_NETWORK}"
    EOF
    {{< /text >}}

1. Instala Istio.

    {{< text syntax=bash snip_id=install_istio >}}
    $ istioctl install -f vm-cluster.yaml
    {{< /text >}}

1. Despliega el east-west gateway:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< warning >}}
    Si el control plane se instaló con una revisión, agrega la opción `--revision rev` al comando `gen-eastwest-gateway.sh`.
    {{< /warning >}}

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Single-Network" category-value="single" >}}

    {{< text syntax=bash snip_id=install_eastwest >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ --single-cluster | istioctl install -y -f -
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Multi-Network" category-value="multiple" >}}

    {{< text syntax=bash snip_id=install_eastwest_multinetwork >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --network "${CLUSTER_NETWORK}" | \
        istioctl install -y -f -
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

    Esto crea un `Service` llamado `istio-eastwestgateway` en el namespace `istio-system`. Anota su
    nombre, lo necesitarás cuando generes los archivos para la virtual machine:

    {{< text syntax=bash snip_id=set_eastwest_service >}}
    $ EASTWEST_GATEWAY_SERVICE="istio-eastwestgateway"
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    Los CRDs de Kubernetes Gateway API no vienen instalados por defecto en la mayoría de los clústeres de Kubernetes, por lo que
    asegúrate de que estén instalados antes de usar Gateway API:

    {{< text syntax=bash snip_id=install_crds >}}
    $ kubectl get crd tlsroutes.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

    {{< warning >}}
    Si estás ejecutando una instancia de istiod con revisión y no tienes una revisión o tag predeterminados,
    puede que necesites agregar la etiqueta `istio.io/rev` al manifiesto `Gateway` que aparece a continuación.
    {{< /warning >}}

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Single-Network" category-value="single" >}}

    La virtual machine solo necesita alcanzar istiod a través del gateway, por lo que el `Gateway` expone los
    puertos de discovery y webhook de istiod como listeners TLS passthrough:

    {{< text syntax="bash yaml" snip_id=install_eastwest_gtwapi >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: eastwestgateway
      namespace: istio-system
    spec:
      gatewayClassName: istio
      listeners:
      - name: tls-istiod
        port: 15012
        protocol: TLS
        tls:
          mode: Passthrough
      - name: tls-istiodwebhook
        port: 15017
        protocol: TLS
        tls:
          mode: Passthrough
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Multi-Network" category-value="multiple" >}}

    Además de los puertos de istiod, el `Gateway` necesita un listener que reenvíe el tráfico de servicios
    entre redes. La etiqueta `topology.istio.io/network` marca el gateway como un gateway multi-network y la
    opción `gateway.istio.io/listener-protocol: auto-passthrough` hace que Istio enrute ese listener por SNI:

    {{< text syntax="bash yaml" snip_id=install_eastwest_gtwapi_multinetwork >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: eastwestgateway
      namespace: istio-system
      labels:
        topology.istio.io/network: "${CLUSTER_NETWORK}"
    spec:
      gatewayClassName: istio
      listeners:
      - name: tls-passthrough
        port: 15443
        protocol: TLS
        tls:
          mode: Passthrough
          options:
            gateway.istio.io/listener-protocol: auto-passthrough
      - name: tls-istiod
        port: 15012
        protocol: TLS
        tls:
          mode: Passthrough
      - name: tls-istiodwebhook
        port: 15017
        protocol: TLS
        tls:
          mode: Passthrough
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

    Istio despliega automáticamente el gateway y crea un `Service` para él, con un nombre derivado del recurso `Gateway`
    y de su gateway class. Anota ese nombre, lo necesitarás cuando generes los archivos para
    la virtual machine:

    {{< text syntax=bash snip_id=set_eastwest_service_gtwapi >}}
    $ EASTWEST_GATEWAY_SERVICE="eastwestgateway-istio"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Expón los servicios dentro del clúster a través del east-west gateway:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Single-Network" category-value="single" >}}

    Expón el control plane:

    {{< text syntax=bash snip_id=expose_istio >}}
    $ kubectl apply -n istio-system -f @samples/multicluster/expose-istiod.yaml@
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Multi-Network" category-value="multiple" >}}

    Expón el control plane:

    {{< text syntax=bash snip_id=expose_istio_multinetwork >}}
    $ kubectl apply -n istio-system -f @samples/multicluster/expose-istiod.yaml@
    {{< /text >}}

    Expón los servicios del clúster:

    {{< text syntax=bash snip_id=expose_services_multinetwork >}}
    $ kubectl apply -n istio-system -f @samples/multicluster/expose-services.yaml@
    {{< /text >}}

    Asegúrate de etiquetar el namespace istio-system con la red del clúster definida:

    {{< text syntax=bash snip_id=label_istio_system_network >}}
    $ kubectl label namespace istio-system topology.istio.io/network="${CLUSTER_NETWORK}"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    Expón el control plane adjuntando un `TLSRoute` a cada uno de los listeners de istiod. Las rutas
    coinciden con el SNI que presenta la virtual machine, que es la parte del host de
    `discoveryAddress` que `istioctl x workload entry configure` escribe en `mesh.yaml`. Ten en cuenta que
    el listener del webhook reenvía al puerto `443` del servicio `istiod`:

    {{< text syntax="bash yaml" snip_id=expose_istio_gtwapi >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: TLSRoute
    metadata:
      name: istiod
      namespace: istio-system
    spec:
      parentRefs:
      - name: eastwestgateway
        sectionName: tls-istiod
      hostnames:
      - istiod.istio-system.svc
      rules:
      - backendRefs:
        - name: istiod
          port: 15012
    ---
    apiVersion: gateway.networking.k8s.io/v1
    kind: TLSRoute
    metadata:
      name: istiod-webhook
      namespace: istio-system
    spec:
      parentRefs:
      - name: eastwestgateway
        sectionName: tls-istiodwebhook
      hostnames:
      - istiod.istio-system.svc
      rules:
      - backendRefs:
        - name: istiod
          port: 443
    EOF
    {{< /text >}}

    {{< warning >}}
    Si el control plane se instaló con una revisión y no tienes una revisión o tag predeterminados,
    la virtual machine se conecta a `istiod-<rev>.istio-system.svc` en su lugar. Usa ese hostname en
    ambas rutas.
    {{< /warning >}}

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Single-Network" category-value="single" >}}

    No se requiere ninguna configuración adicional. La virtual machine alcanza los pods del clúster directamente mediante
    redes L3.

    {{< /tab >}}

    {{< tab name="Multi-Network" category-value="multiple" >}}

    Los servicios del clúster ya están expuestos por el listener `auto-passthrough` que configuraste en el
    `Gateway`, por lo que no se necesita ninguna ruta para ellos. Solo necesitas etiquetar el namespace istio-system con
    la red del clúster definida:

    {{< text syntax=bash snip_id=label_istio_system_network_gtwapi >}}
    $ kubectl label namespace istio-system topology.istio.io/network="${CLUSTER_NETWORK}"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

    {{< /tab >}}

    {{< /tabset >}}

## Configurar el namespace de la VM

1. Crea el namespace que alojará la virtual machine:

    {{< text syntax=bash snip_id=install_namespace >}}
    $ kubectl create namespace "${VM_NAMESPACE}"
    {{< /text >}}

1. Crea una serviceaccount para la virtual machine:

    {{< text syntax=bash snip_id=install_sa >}}
    $ kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"
    {{< /text >}}

## Crear los archivos para transferir a la virtual machine

Primero, crea un `WorkloadGroup` de plantilla para la(s) VM:

{{< text syntax=bash snip_id=create_wg >}}
$ cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF
{{< /text >}}

Luego, para permitir la creación automatizada de `WorkloadEntry`, envía el `WorkloadGroup` al clúster:

{{< text syntax=bash snip_id=apply_wg >}}
$ kubectl --namespace "${VM_NAMESPACE}" apply -f workloadgroup.yaml
{{< /text >}}

{{< tip >}}
También están disponibles los health checks de la aplicación, que comparten la misma API y comportamiento que los [Readiness Probes de Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).
Agrega un `probe` a la especificación del `WorkloadGroup`, por ejemplo para sondear el endpoint `/ready` de tu aplicación:

{{< text yaml >}}
spec:
  probe:
    periodSeconds: 5
    initialDelaySeconds: 1
    httpGet:
      port: 8080
      path: /ready
{{< /text >}}

Con esta configuración, el `WorkloadEntry` generado automáticamente no se marcará como "Ready" hasta que el probe tenga éxito.
{{< /tip >}}

A continuación, usa el comando `istioctl x workload entry` para generar:

* `cluster.env`: Contiene metadatos que identifican el namespace, la service account, el CIDR de red y (opcionalmente) qué puertos de entrada capturar.
* `istio-token`: Un token de Kubernetes usado para obtener certificados de la CA.
* `mesh.yaml`: Proporciona `ProxyConfig` para configurar `discoveryAddress`, los probes de health checking y algunas opciones de autenticación.
* `root-cert.pem`: El certificado raíz usado para autenticar.
* `hosts`: Un complemento para `/etc/hosts` que el proxy usará para alcanzar istiod para xDS.*

{{< idea >}}
Una opción más sofisticada consiste en configurar el DNS dentro de la virtual
machine para que haga referencia a un servidor DNS externo. Esta opción queda fuera
del alcance de esta guía.
{{< /idea >}}

{{< tabset category-name="registration-mode" >}}

{{< tab name="Default" category-value="default" >}}

{{< text syntax=bash snip_id=configure_wg_default >}}
$ istioctl x workload entry configure \
    -f workloadgroup.yaml \
    -o "${WORK_DIR}" \
    --ingressService "${EASTWEST_GATEWAY_SERVICE}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Automated WorkloadEntry Creation" category-value="autoreg" >}}

{{< boilerplate alpha >}}

{{< text syntax=bash snip_id=configure_wg >}}
$ istioctl x workload entry configure \
    -f workloadgroup.yaml \
    -o "${WORK_DIR}" \
    --ingressService "${EASTWEST_GATEWAY_SERVICE}" \
    --autoregister
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< tip >}}
El archivo `hosts` generado asocia el hostname de istiod con la dirección IP del east-west gateway, que el
comando lee del load balancer o de la IP externa del `Service` indicado en `--ingressService`.

Si la dirección no se puede resolver a una IP, ya sea porque no se encontró el `Service` o porque el load
balancer es accesible mediante un hostname, el archivo `hosts` se genera vacío y la virtual machine
no podrá alcanzar istiod. Pasa `--ingressIP` con la dirección del gateway para establecerla explícitamente.

Como alternativa, expón istiod bajo un nombre DNS que la virtual machine ya pueda resolver y omite por completo el
paso de `/etc/hosts`. Esto requiere instalar el control plane con
`values.pilot.env.ISTIOD_CUSTOM_HOST` establecido a ese nombre, para que istiod firme su certificado de servicio para él,
reemplazar `defaultConfig.discoveryAddress` en `mesh.yaml` por `<custom-host>:15012`, y establecer `CA_ADDR`
en `cluster.env` a la misma dirección.
{{< /tip >}}

## Configurar la virtual machine {#configure-the-virtual-machine}

Ejecuta los siguientes comandos en la virtual machine que quieres agregar a la mesh de Istio:

1. Transfiere de forma segura los archivos de `"${WORK_DIR}"`
    a la virtual machine. La forma de transferir esos archivos de manera segura debe decidirse teniendo en cuenta
    tus políticas de seguridad de la información. Para mayor comodidad en esta guía, transfiere todos los archivos necesarios a `"${HOME}"` en la virtual machine.

1. Instala el certificado raíz en `/etc/certs`:

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp "${HOME}"/root-cert.pem /etc/certs/root-cert.pem
    {{< /text >}}

1. Instala el token en `/var/run/secrets/tokens`:

    {{< text bash >}}
    $ sudo  mkdir -p /var/run/secrets/tokens
    $ sudo cp "${HOME}"/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}

1. Instala el paquete que contiene el runtime de integración de virtual machines de Istio:

    {{< tabset category-name="vm-os" >}}

    {{< tab name="Debian" category-value="debian" >}}

    {{< text syntax=bash snip_id=none >}}
    $ curl -LO https://blob.istio.io/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="CentOS" category-value="centos" >}}

    Nota: actualmente solo se soporta CentOS 8.

    {{< text syntax=bash snip_id=none >}}
    $ curl -LO https://blob.istio.io/istio-release/releases/{{< istio_full_version >}}/rpm/istio-sidecar.rpm
    $ sudo rpm -i istio-sidecar.rpm
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Instala `cluster.env` en el directorio `/var/lib/istio/envoy/`:

    {{< text bash >}}
    $ sudo cp "${HOME}"/cluster.env /var/lib/istio/envoy/cluster.env
    {{< /text >}}

1. Instala el [Mesh Config](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) en `/etc/istio/config/mesh`:

    {{< text bash >}}
    $ sudo cp "${HOME}"/mesh.yaml /etc/istio/config/mesh
    {{< /text >}}

1. Agrega el host de istiod a `/etc/hosts`:

    {{< text bash >}}
    $ sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts >> /etc/hosts'
    {{< /text >}}

1. Transfiere la propiedad de los archivos en `/etc/certs/` y `/var/lib/istio/envoy/` al proxy de Istio:

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/proxy
    $ sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem
    {{< /text >}}

## Iniciar Istio dentro de la virtual machine

1. Inicia el agente de Istio:

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}

## Verificar que Istio funciona correctamente

1. Revisa el log en `/var/log/istio/istio.log`. Deberías ver entradas similares a las siguientes:

    {{< text bash >}}
    $ 2020-08-21T01:32:17.748413Z info sds resource:default pushed key/cert pair to proxy
    $ 2020-08-21T01:32:20.270073Z info sds resource:ROOTCA new connection
    $ 2020-08-21T01:32:20.270142Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.270279Z info cache adding watcher for file ./etc/certs/root-cert.pem
    $ 2020-08-21T01:32:20.270347Z info cache GenerateSecret from file ROOTCA
    $ 2020-08-21T01:32:20.270494Z info sds resource:ROOTCA pushed root cert to proxy
    $ 2020-08-21T01:32:20.270734Z info sds resource:default new connection
    $ 2020-08-21T01:32:20.270763Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.695478Z info cache GenerateSecret default
    $ 2020-08-21T01:32:20.695595Z info sds resource:default pushed key/cert pair to proxy
    {{< /text >}}

1. Crea un Namespace para desplegar un Service basado en Pods:

    {{< text bash >}}
    $ kubectl create namespace sample
    $ kubectl label namespace sample istio-injection=enabled
    {{< /text >}}

1. Despliega el Service `HelloWorld`:

    {{< text bash >}}
    $ kubectl apply -n sample -f @samples/helloworld/helloworld.yaml@
    {{< /text >}}

1. Envía solicitudes desde tu Virtual Machine al Service:

    {{< text bash >}}
    $ curl helloworld.sample.svc:5000/hello
    Hello version: v1, instance: helloworld-v1-578dd69f69-fxwwk
    {{< /text >}}

## Próximos pasos

Para más información sobre virtual machines:

* [Depuración de Virtual Machines](/es/docs/ops/diagnostic-tools/virtual-machines/) para solucionar problemas con virtual machines.
* [Bookinfo con una Virtual Machine](/es/docs/examples/virtual-machines/) para configurar un despliegue de ejemplo de virtual machines.

## Desinstalar {#uninstall}

Detén Istio en la virtual machine:

{{< text bash >}}
$ sudo systemctl stop istio
{{< /text >}}

Luego, elimina el paquete istio-sidecar:

{{< tabset category-name="vm-os" >}}

{{< tab name="Debian" category-value="debian" >}}

{{< text bash >}}
$ sudo dpkg -r istio-sidecar
$ dpkg -s istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< tab name="CentOS" category-value="centos" >}}

{{< text bash >}}
$ sudo rpm -e istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Para desinstalar Istio, ejecuta el siguiente comando:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=uninstall_istio >}}
$ kubectl delete -n istio-system -f @samples/multicluster/expose-istiod.yaml@
$ istioctl uninstall -y --purge
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=uninstall_istio_gtwapi >}}
$ kubectl delete tlsroute istiod istiod-webhook -n istio-system
$ kubectl delete gtw eastwestgateway -n istio-system
$ istioctl uninstall -y --purge
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

El namespace del control plane (por ejemplo, `istio-system`) no se elimina por defecto.
Si ya no lo necesitas, usa el siguiente comando para eliminarlo:

{{< text syntax=bash snip_id=delete_istio_namespace >}}
$ kubectl delete namespace istio-system
{{< /text >}}
