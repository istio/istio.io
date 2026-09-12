---
title: Dashboard Kiali para ambient multi-red
description: Configura una instancia federada de Prometheus y despliega Kiali en ambient multi-red.
weight: 70
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/verify
---
Sigue esta guía para desplegar Kiali multiclúster en un despliegue ambient multi-red para visualizar
cómo fluye el tráfico entre los clústeres.

Antes de proceder, asegúrate de completar los pasos en
[antes de comenzar](/docs/ambient/install/multicluster/before-you-begin), las [guías de instalación multiclúster](/docs/ambient/install/multicluster) y [verificar tu despliegue](/docs/ambient/install/multicluster/verify).

En esta guía comenzaremos desplegando una instancia federada de Prometheus para agregar métricas de
todos los clústeres juntos. Luego procederemos a desplegar una instancia personalizada de Kiali que se conecta a todos los
clústeres y presenta una vista unificada del tráfico de la mesh.

{{< warning >}}
La configuración mostrada en esta guía está pensada para ser simple y no es una
configuración recomendada para producción. Para mejores prácticas en la configuración de Prometheus en producción, consulta
[Usar Prometheus para monitoreo a escala de producción](/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring).
Para más detalles sobre los despliegues de Kiali, consulta la [documentación de Kiali](https://kiali.io/docs/).
{{< /warning >}}

## Preparar el despliegue de Kiali

Instalaremos Prometheus y Kiali personalizados en un namespace separado, así que comencemos
creando el namespace en ambos clústeres:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" create namespace kiali
$ kubectl --context="${CTX_CLUSTER2}" create namespace kiali
{{< /text >}}

También usaremos `helm` para desplegar Kiali, así que agreguemos los repositorios de Helm relevantes:

{{< text bash >}}
$ helm repo add kiali https://kiali.org/helm-charts
{{< /text >}}

## Prometheus federado

Istio proporciona una instalación de ejemplo básica para poner en marcha Prometheus rápidamente en despliegues de un solo clúster — usaremos eso para instalar Prometheus en cada clúster. Luego desplegaremos otra
instancia de Prometheus que hará scraping de Prometheus en cada clúster y agregará las métricas juntas.

Para poder hacer scraping de Prometheus en el clúster remoto, expondremos la instancia de Prometheus a través de un Ingress
Gateway.

### Desplegar Prometheus en cada clúster

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -f {{< github_file >}}/samples/addons/prometheus.yaml
$ kubectl --context="${CTX_CLUSTER2}" apply -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}

Los comandos anteriores instalarán Prometheus que recopila métricas locales del clúster de waypoints y
ztunnels.

### Exponer Prometheus

El siguiente paso es exponer las instancias de Prometheus externamente para que puedan hacer scraping:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
{{< /text >}}

Haremos lo mismo en el segundo clúster también:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
{{< /text >}}

### Agregar métricas

Con las instancias de Prometheus locales de cada clúster en funcionamiento, ahora podemos configurar otra instancia de Prometheus
que las hará scraping para recopilar métricas de ambos clústeres en un solo lugar. Comenzaremos creando una
configuración para la nueva instancia de Prometheus que la apuntará a las instancias locales de Prometheus de cada clúster:

{{< text bash >}}
$ TARGET1="$(kubectl --context="${CTX_CLUSTER1}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
$ TARGET2="$(kubectl --context="${CTX_CLUSTER2}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
$ cat <<EOF > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'federate-1'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targets:
        - '${TARGET1}:9090'
        labels:
          cluster: 'cluster1'
  - job_name: 'federate-2'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targets:
        - '${TARGET2}:9090'
        labels:
          cluster: 'cluster2'
EOF
$ kubectl --context="${CTX_CLUSTER1}" create configmap prometheus-config -n kiali --from-file prometheus.yml
{{< /text >}}

Ahora podemos usar esa configuración para desplegar una nueva instancia de Prometheus:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config-volume
              mountPath: /etc/prometheus
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
            defaultMode: 420
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  labels:
    app: prometheus
    service: prometheus
spec:
  ports:
  - port: 9090
    name: http
  selector:
    app: prometheus
EOF
{{< /text >}}

Una vez desplegada, la nueva instancia de Prometheus comenzará a hacer scraping de métricas de ambos clústeres.

### Verificar Prometheus federado

Para probar, podemos generar algo de tráfico ejecutando `curl` varias veces para llegar a backends en ambos
clústeres:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Luego podemos consultar Prometheus usando `curl` para ver si tenemos métricas reportadas de todos los clústeres:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pods ---context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s prometheus.kiali:9090/api/v1/query?query=istio_tcp_received_bytes_total | jq '.'
{{< /text >}}

Si el request de `curl` llegó a backends en ambos clústeres, para la métrica `istio_tcp_received_bytes_total`
reportada por `ztunnel` deberías poder ver valores de ambos clústeres en la salida:

{{< text plain >}}
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster2",
          ...
          "destination_canonical_revision": "v2",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "5040"
        ]
      },
      ...
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster1",
          ...
          "destination_canonical_revision": "v1",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "4704"
        ]
      },
      ...
    ]
  }
}
{{< /text >}}

## Desplegar Kiali multiclúster

### Preparar el clúster remoto

Solo desplegaremos Kiali propiamente en un clúster — `cluster1`, sin embargo aún necesitamos preparar
`cluster2` para que Kiali pueda acceder a los recursos ahí. Para esto comenzaremos
desplegando el Operador de Kiali:

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER2}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
{{< /text >}}

Una vez que tengamos el Operador de Kiali desplegado, podemos preparar todas las cuentas de servicio, role bindings y tokens necesarios. El Operador de Kiali creará la cuenta de servicio y los role bindings, pero tendremos que crear el token para la cuenta de servicio manualmente:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  deployment:
    remote_cluster_resources_only: true
EOF
$ kubectl --context="${CTX_CLUSTER2}" wait --timeout=5m --for=condition=Successful kiali kiali -n kiali
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: kiali
  annotations:
    kubernetes.io/service-account.name: kiali-service-account
type: kubernetes.io/service-account-token
EOF
{{< /text >}}

### Desplegar Kiali

Con el clúster remoto listo, ahora podemos desplegar el servidor Kiali. Necesitaremos configurar Kiali con
la dirección del endpoint de Prometheus y el secreto para acceder al clúster remoto. Como antes,
comenzaremos desplegando el Operador de Kiali:

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER1}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
{{< /text >}}

El proyecto Kiali proporciona un script que podemos usar para crear el secreto necesario para acceder a los recursos del clúster remoto:

{{< text bash >}}
$ curl -L -o kiali-prepare-remote-cluster.sh https://raw.githubusercontent.com/kiali/kiali/master/hack/istio/multicluster/kiali-prepare-remote-cluster.sh
$ chmod +x kiali-prepare-remote-cluster.sh
$ ./kiali-prepare-remote-cluster.sh \
    --kiali-cluster-context "${CTX_CLUSTER1}" \
    --remote-cluster-context "${CTX_CLUSTER2}" \
    --view-only false \
    --process-kiali-secret true \
    --process-remote-resources false \
    --kiali-cluster-namespace kiali \
    --remote-cluster-namespace kiali \
    --kiali-resource-name kiali \
    --remote-cluster-name cluster2
{{< /text >}}

Con el secreto remoto listo, ahora podemos desplegar el servidor Kiali:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  external_services:
    prometheus:
      url: http://prometheus.kiali:9090
    grafana:
      enabled: false
  server:
    web_root: "/kiali"
EOF
$ kubectl --context="${CTX_CLUSTER1}" wait --timeout=5m --for=condition=Successful kiali kiali -n kiali
{{< /text >}}

Una vez que el servidor Kiali esté en ejecución, podemos hacer port-forward de un puerto local al deployment de Kiali para acceder localmente:

{{< text syntax=bash snip_id=none >}}
$ kubectl --context="${CTX_CLUSTER1}" port-forward svc/kiali 20001:20001 -n kiali
{{< /text >}}

Abre el dashboard de Kiali en el navegador, navega al gráfico de tráfico y selecciona el namespace "sample"
desde el desplegable "Select Namespaces". Deberías ver cómo fluye el tráfico entre
los clústeres:

{{< image link="./kiali-traffic-graph.png" caption="Dashboard del gráfico de tráfico de Kiali" >}}

{{< tip >}}
Si no ves el gráfico de tráfico, intenta generar más tráfico y/o extender la ventana de tiempo que
considera Kiali.
{{</ tip >}}

**¡Felicitaciones!** Instalaste exitosamente Kiali para el despliegue ambient multiclúster.

## Limpieza de Kiali y Prometheus

Para eliminar Kiali, comienza borrando el recurso personalizado de Kiali:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete kiali kiali -n kiali
$ kubectl --context="${CTX_CLUSTER2}" delete kiali kiali -n kiali
{{< /text >}}

El Operador de Kiali detendrá el servidor Kiali una vez que se elimine el recurso personalizado. Si también quieres
eliminar el Operador de Kiali puedes hacerlo:

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER1}" uninstall --namespace kiali kiali-operator
$ helm --kube-context="${CTX_CLUSTER2}" uninstall --namespace kiali kiali-operator
{{< /text >}}

Finalmente, puedes eliminar las definiciones de recursos personalizados:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete crd kialis.kiali.io
{{< /text >}}

Si no necesitas las instancias locales de Prometheus de cada clúster, también puedes eliminarlas:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete -f {{< github_file >}}/samples/addons/prometheus.yaml
$ kubectl --context="${CTX_CLUSTER2}" delete -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}
