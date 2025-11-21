---
title: Instalando Gateways
description: Instala y personaliza Gateways de Istio.
weight: 40
keywords: [install,gateway,kubernetes]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
{{< boilerplate gateway-api-future >}}
Si usas el API Gateway, no necesitarás instalar y gestionar un `Deployment` de gateway como se describe en este documento.
Por defecto, un `Deployment` y `Service` de gateway será aprovisionado automáticamente basado en la configuración de `Gateway`.
Consulta la [tarea del API Gateway](/es/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) para más detalles.
{{< /tip >}}

Junto con crear un service mesh, Istio te permite gestionar [gateways](/es/docs/concepts/traffic-management/#gateways),
que son proxies Envoy ejecutándose en el borde de la mesh, proporcionando control granular sobre el tráfico que entra y sale de la mesh.

Algunos de los [perfiles de configuración](/es/docs/setup/additional-setup/config-profiles/) incorporados de Istio despliegan gateways durante la instalación.
Por ejemplo, una llamada a `istioctl install` con [configuración por defecto](/es/docs/setup/install/istioctl/#install-istio-using-the-default-profile)
desplegará un gateway de ingreso junto con el control plane.
Aunque está bien para evaluación y casos de uso simples, esto acopla el gateway al control plane, haciendo la gestión y actualización más complicada.
Para deployments de Istio en producción, se recomienda encarecidamente desacoplar estos para permitir operación independiente.

Sigue esta guía para desplegar y gestionar uno o más gateways por separado en una instalación de producción de Istio.

## Prerrequisitos

Esta guía requiere que el control plane de Istio [esté instalado](/es/docs/setup/install/) antes de proceder.
{{< tip >}}
Puedes usar el perfil `minimal`, por ejemplo `istioctl install --set profile=minimal`, para evitar que se desplieguen gateways 
durante la instalación.
{{< /tip >}}

## Deploying a gateway

Usando los mismos mecanismos que [la inyección automática de sidecars de Istio](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection),
la configuración del proxy Envoy para gateways también puede ser auto-inyectada.

Se recomienda usar la auto-inyección para los despliegues de gateways, ya que brinda a los desarrolladores control total sobre el despliegue del gateway,
mientras simplifica las operaciones.
Cuando hay una nueva actualización disponible o ha cambiado una configuración, los pods del gateway pueden ser actualizados simplemente reiniciándolos.
Esto hace que la experiencia de operar un despliegue de gateway sea similar a la de operar sidecars.

Para apoyar a los usuarios con herramientas de despliegue existentes, Istio proporciona varias formas de desplegar un gateway.
Cada método producirá el mismo resultado.
Elige el método con el que estés más familiarizado.

{{< tip >}}
Como una práctica de seguridad recomendada, se sugiere desplegar el gateway en un namespace diferente al del control plane.
{{< /tip >}}

Todos los métodos listados a continuación dependen de [la inyección](/es/docs/setup/additional-setup/sidecar-injection/) para completar configuraciones adicionales de los pods en tiempo de ejecución.
Para soportar esto, el namespace donde se despliega el gateway no debe tener la etiqueta `istio-injection=disabled`.
Si la tiene, verás que los pods fallan al iniciar intentando obtener la imagen `auto`, que es un marcador de posición que se reemplaza cuando se crea un pod.

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Primero, configura un archivo de configuración `IstioOperator`, llamado `ingress.yaml` aquí:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: ingress
spec:
  profile: empty # Do not install CRDs or the control plane
  components:
    ingressGateways:
    - name: istio-ingressgateway
      namespace: istio-ingress
      enabled: true
      label:
        # Set a unique label for the gateway. This is required to ensure Gateways
        # can select this workload
        istio: ingressgateway
  values:
    gateways:
      istio-ingressgateway:
        # Enable gateway injection
        injectionTemplate: gateway
{{< /text >}}

Luego instala usando comandos estándar de `istioctl`:

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ istioctl install -f ingress.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Instalar usando comandos estándar de `helm`:

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ helm install istio-ingressgateway istio/gateway -n istio-ingress
{{< /text >}}

Para ver los posibles valores de configuración compatibles, ejecuta `helm show values istio/gateway`.
El repositorio [README](https://artifacthub.io/packages/helm/istio-official/gateway) de Helm contiene información adicional sobre el uso.

{{< tip >}}

Cuando despliegues el gateway en un clúster de OpenShift, utiliza el perfil `openshift` para sobrescribir los valores predeterminados, por ejemplo:

{{< text bash >}}
$ helm install istio-ingressgateway istio/gateway -n istio-ingress --set global.platform=openshift
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Kubernetes YAML" category-value="yaml" >}}

Primero, configura el archivo de configuración de Kubernetes, llamado `ingress.yaml` aquí:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-ingress
spec:
  type: LoadBalancer
  selector:
    istio: ingressgateway
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway
  namespace: istio-ingress
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      annotations:
        # Select the gateway injection template (rather than the default sidecar template)
        inject.istio.io/templates: gateway
      labels:
        # Set a unique label for the gateway. This is required to ensure Gateways can select this workload
        istio: ingressgateway
        # Enable gateway injection. If connecting to a revisioned control plane, replace with "istio.io/rev: revision-name"
        sidecar.istio.io/inject: "true"
    spec:
      # Allow binding to all ports (such as 80 and 443)
      securityContext:
        sysctls:
        - name: net.ipv4.ip_unprivileged_port_start
          value: "0"
      containers:
      - name: istio-proxy
        image: auto # The image will automatically update each time the pod starts.
        # Drop all privileges, allowing to run as non-root
        securityContext:
          capabilities:
            drop:
            - ALL
          runAsUser: 1337
          runAsGroup: 1337
---
# Set up roles to allow reading credentials for TLS
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: istio-ingressgateway-sds
  namespace: istio-ingress
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: istio-ingressgateway-sds
  namespace: istio-ingress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: istio-ingressgateway-sds
subjects:
- kind: ServiceAccount
  name: default
{{< /text >}}

{{< warning >}}
Este ejemplo muestra lo mínimo necesario para que un gateway funcione. Para uso en producción, se recomienda una configuración adicional como `HorizontalPodAutoscaler`, `PodDisruptionBudget` y solicitudes/límites de recursos. Estos se incluyen automáticamente al usar los otros métodos de instalación de gateways.
{{< /warning >}}

{{< tip >}}
La etiqueta `sidecar.istio.io/inject` en el pod se utiliza en este ejemplo para habilitar la inyección. Al igual que la inyección de sidecars de aplicaciones, esto también puede controlarse a nivel de namespace. Consulta [Controlando la política de inyección](/es/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy) para más información.
{{< /tip >}}

A continuación, aplícalo al clúster:

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ kubectl apply -f ingress.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Gestionando gateways

Lo siguiente describe cómo gestionar gateways después de la instalación. Para más información sobre su uso, sigue
las tareas de [Ingress](/es/docs/tasks/traffic-management/ingress/) y [Egress](/es/docs/tasks/traffic-management/egress/).

### Selectores de Gateway

Las etiquetas en los pods de un despliegue de gateway son utilizadas por los recursos de configuración `Gateway`, por lo que es importante que
tu selector de `Gateway` coincida con estas etiquetas.

Por ejemplo, en los despliegues anteriores, la etiqueta `istio=ingressgateway` se establece en los pods del gateway.
Para aplicar un `Gateway` a estos despliegues, necesitas seleccionar la misma etiqueta:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
...
{{< /text >}}

### Topologías de despliegue de Gateway

Dependiendo de la configuración de tu meshy casos de uso, es posible que desees desplegar gateways de diferentes maneras.
A continuación se muestran algunos patrones de despliegue de gateways.
Ten en cuenta que se pueden usar más de uno de estos patrones dentro del mismo clúster.

#### Gateway compartido

En este modelo, un gateway centralizado único es utilizado por muchas aplicaciones, posiblemente a través de muchos namespaces.
Los Gateway(s) en el namespace `ingress` delegan la propiedad de las rutas a los namespaces de las aplicaciones, pero mantienen el control sobre la configuración de TLS.

{{< image width="50%" link="shared-gateway.svg" caption="Gateway compartido" >}}

Este modelo funciona bien cuando tienes muchas aplicaciones que deseas exponer externamente, ya que pueden usar infraestructura compartida.
También funciona bien en casos de uso que tienen el mismo dominio o certificados TLS compartidos por muchas aplicaciones.

#### Gateway dedicado para aplicaciones

En este modelo, un namespace de aplicación tiene su propia instalación de gateway dedicada.
Esto permite otorgar control total y propiedad a un único namespace.
Este nivel de aislamiento puede ser útil para aplicaciones críticas que tienen requisitos estrictos de rendimiento o seguridad.

{{< image width="50%" link="user-gateway.svg" caption="Gateway dedicado a aplicaciones" >}}

A menos que haya otro balanceador de carga frente a Istio, esto típicamente significa que cada aplicación tendrá su propia dirección IP, lo que puede complicar las configuraciones de DNS.

## Actualización de gateways

### Actualización en el lugar

Debido a que los gateways utilizan la inyección de pods, los nuevos pods de gateway que se creen serán automáticamente inyectados con la configuración más reciente, que incluye la versión.

Para aplicar los cambios a la configuración del gateway, los pods simplemente pueden ser reiniciados, utilizando comandos como `kubectl rollout restart deployment`.

Si deseas cambiar la [revisión del control plane](/es/docs/setup/upgrade/canary/) utilizada por el gateway, puedes establecer la etiqueta `istio.io/rev` en el Deployment del gateway, lo que también desencadenará un reinicio progresivo.

{{< image width="50%" link="inplace-upgrade.svg" caption="In place upgrade en progreso" >}}

### Canary upgrade (avanzado)
{{< warning >}}
Este método de actualización depende de las revisiones del control plane, y por lo tanto solo puede ser utilizado junto con
[actualización canaria del control plane](/es/docs/setup/upgrade/canary/).
{{< /warning >}}

Si deseas controlar más lentamente el despliegue de una nueva revisión del control plane, puedes ejecutar múltiples versiones de un despliegue de gateway.
Por ejemplo, si deseas desplegar una nueva revisión, `canary`, crea una copia de tu despliegue de gateway con la etiqueta `istio.io/rev=canary` configurada:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway-canary
  namespace: istio-ingress
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        istio: ingressgateway
        istio.io/rev: canary # Set to the control plane revision you want to deploy
    spec:
      containers:
      - name: istio-proxy
        image: auto
{{< /text >}}

Cuando se crea este despliegue, tendrás entonces dos versiones del gateway, ambas seleccionadas por el mismo Service:

{{< text bash >}}
$ kubectl get endpoints -n istio-ingress -o "custom-columns=NAME:.metadata.name,PODS:.subsets[*].addresses[*].targetRef.name"
NAME                   PODS
istio-ingressgateway   istio-ingressgateway-...,istio-ingressgateway-canary-...
{{< /text >}}

{{< image width="50%" link="canary-upgrade.svg" caption="Canary upgrade en progreso" >}}

A diferencia de los servicios de aplicaciones desplegados dentro de la mesh, no puedes usar [redirección de tráfico de Istio](/es/docs/tasks/traffic-management/traffic-shifting/) para distribuir el tráfico entre las versiones del gateway porque su tráfico proviene directamente de clientes externos que Istio no controla. 
En su lugar, puedes controlar la distribución del tráfico mediante el número de réplicas de cada despliegue. 
Si utilizas otro balanceador de carga frente a Istio, también puedes usarlo para controlar la distribución del tráfico.

{{< warning >}}
Debido a que otros métodos de instalación agrupan el `Service` del gateway, que controla su dirección IP externa, con el `Deployment` del gateway, solo el método [Kubernetes YAML](/es/docs/setup/additional-setup/gateway/#tabset-docs-setup-additional-setup-gateway-1-2-tab) es compatible con este método de actualización.
{{< /warning >}}

### Actualización canaria con redirección de tráfico externo (avanzado)

Una variante del enfoque de [actualización canaria](#canary-upgrade) es redirigir el tráfico entre las versiones utilizando una construcción de alto nivel fuera de Istio, como un balanceador de carga externo o DNS.

{{< image width="50%" link="high-level-canary.svg" caption="Canary upgrade en progreso con redirección de tráfico externo" >}}

Esto ofrece un control granular, pero puede ser inadecuado o demasiado complicado de configurar en algunos entornos.

## Limpieza

- Limpieza del gateway de ingreso de Istio

    {{< text bash >}}
    $ istioctl uninstall --istioNamespace istio-ingress -y --purge
    $ kubectl delete ns istio-ingress
    {{< /text >}}
