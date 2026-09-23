---
title: Verificación de Salud de Services de Istio
description: Muestra cómo hacer verificación de salud para Services de Istio.
weight: 50
aliases:
  - /docs/tasks/traffic-management/app-health-check/
  - /docs/ops/security/health-checks-and-mtls/
  - /help/ops/setup/app-health-check
  - /help/ops/app-health-check
  - /docs/ops/app-health-check
  - /docs/ops/setup/app-health-check
keywords: [security,health-check]
owner: istio/wg-user-experience-maintainers
test: yes
---

[Las sondas de liveness y readiness de Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
describe varias maneras de configurar sondas de liveness y readiness:

1. [Comando](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)
1. [Solicitud HTTP](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request)
1. [Sonda TCP](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-tcp-liveness-probe)
1. [Sonda gRPC](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-grpc-liveness-probe)

El enfoque de comando funciona sin cambios requeridos, pero las solicitudes HTTP, sondas TCP, y sondas gRPC requieren que Istio haga cambios a la configuración del pod.

Las solicitudes de verificación de salud al Service `liveness-http` son enviadas por Kubelet.
Esto se convierte en un problema cuando mutual TLS está habilitado, porque el Kubelet no tiene un certificado emitido por Istio.
Por lo tanto, las solicitudes de verificación de salud fallarán.

Las verificaciones de sonda TCP necesitan manejo especial, porque Istio redirige todo el tráfico entrante hacia el sidecar, y así todos los puertos TCP aparecen abiertos. El Kubelet simplemente verifica si algún proceso está escuchando en el puerto especificado, y así la sonda siempre tendrá éxito mientras el sidecar esté ejecutándose.

Istio resuelve ambos problemas reescribiendo la sonda readiness/liveness de la aplicación `PodSpec`,
para que la solicitud de sonda sea enviada al [sidecar agent](/es/docs/reference/commands/pilot-agent/).

## Ejemplo de reescritura de sonda liveness

Para demostrar cómo la sonda readiness/liveness es reescrita a nivel de `PodSpec` de la aplicación, usemos el [ejemplo liveness-http-same-port]({{< github_file >}}/samples/health-check/liveness-http-same-port.yaml).

Primero crea y etiqueta un namespace para el ejemplo:

{{< text bash >}}
$ kubectl create namespace istio-io-health-rewrite
$ kubectl label namespace istio-io-health-rewrite istio-injection=enabled
{{< /text >}}

Y despliega la aplicación de ejemplo:

{{< text bash yaml >}}
$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
  namespace: istio-io-health-rewrite
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
{{< /text >}}

Una vez desplegado, puedes inspeccionar el contenedor de aplicación del pod para ver la ruta cambiada:

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o json | jq '.spec.containers[0].livenessProbe.httpGet'
{
  "path": "/app-health/liveness-http/livez",
  "port": 15020,
  "scheme": "HTTP"
}
{{< /text >}}

La ruta `livenessProbe` original ahora está mapeada contra la nueva ruta en la variable de entorno del contenedor sidecar `ISTIO_KUBE_APP_PROBERS`:

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o=jsonpath="{.spec.containers[1].env[?(@.name=='ISTIO_KUBE_APP_PROBERS')]}"
{
  "name":"ISTIO_KUBE_APP_PROBERS",
  "value":"{\"/app-health/liveness-http/livez\":{\"httpGet\":{\"path\":\"/foo\",\"port\":8001,\"scheme\":\"HTTP\"},\"timeoutSeconds\":1}}"
}
{{< /text >}}

Para solicitudes HTTP y gRPC, el sidecar agent redirige la solicitud a la aplicación y quita el cuerpo de respuesta, retornando solo el código de respuesta. Para sondas TCP, el sidecar agent hará entonces la verificación del puerto mientras evita la redirección de tráfico.

La reescritura de sondas problemáticas está habilitada por defecto en todos los
[perfiles de configuración](/es/docs/setup/additional-setup/config-profiles/) integrados de Istio pero puede deshabilitarse como se describe a continuación.

## Sondas de liveness y readiness usando el enfoque de comando

Istio proporciona un [ejemplo de liveness]({{< github_file >}}/samples/health-check/liveness-command.yaml) que
implementa este enfoque. Para demostrar que funciona con mutual TLS habilitado,
primero crea un namespace para el ejemplo:

{{< text bash >}}
$ kubectl create ns istio-io-health
{{< /text >}}

Para configurar mutual TLS estricto, ejecuta:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-io-health"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Después, cambia el directorio a la raíz de la instalación de Istio y ejecuta el siguiente comando para desplegar el Service de ejemplo:

{{< text bash >}}
$ kubectl -n istio-io-health apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

Para confirmar que las sondas de liveness están funcionando, verifica el estado del pod de ejemplo para verificar que esté ejecutándose.

{{< text bash >}}
$ kubectl -n istio-io-health get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

## Sondas de liveness y readiness usando el enfoque HTTP, TCP, y gRPC {#liveness-and-readiness-probes-using-the-http-request-approach}

Como se mencionó anteriormente, Istio usa reescritura de sonda para implementar sondas HTTP, TCP, y gRPC por defecto. Puedes deshabilitar esta
característica ya sea para pods específicos, o globalmente.

### Deshabilitar la reescritura de sonda para un pod {#disable-the-http-probe-rewrite-for-a-pod}

Puedes [anotar el pod](/es/docs/reference/config/annotations/) con `sidecar.istio.io/rewriteAppHTTPProbers: "false"`
para deshabilitar la opción de reescritura de sonda. Asegúrate de agregar la anotación al
[recurso pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) porque será ignorada
en cualquier otro lugar (por ejemplo, en un recurso deployment envolvente).

{{< tabset category-name="disable-probe-rewrite" >}}

{{< tab name="Sonda HTTP" category-value="http-probe" >}}

{{< text yaml >}}
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Sonda gRPC" category-value="grpc-probe" >}}

{{< text yaml >}}
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-grpc
spec:
  selector:
    matchLabels:
      app: liveness-grpc
      version: v1
  template:
    metadata:
      labels:
        app: liveness-grpc
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: etcd
        image: registry.k8s.io/etcd:3.5.1-0
        command: ["--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
        ports:
        - containerPort: 2379
        livenessProbe:
          grpc:
            port: 2379
          initialDelaySeconds: 10
          periodSeconds: 5
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Este enfoque te permite deshabilitar la reescritura de verificación de salud gradualmente en deployments individuales,
sin reinstalar Istio.

### Deshabilitar la reescritura de sonda globalmente

[Instala Istio](/es/docs/setup/install/istioctl/) usando `--set values.sidecarInjectorWebhook.rewriteAppHTTPProbe=false`
para deshabilitar la reescritura de sonda globalmente. **Alternativamente**, actualiza el mapa de configuración para el inyector de sidecar de Istio:

{{< text bash >}}
$ kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -
{{< /text >}}

## Limpieza

Remueve los namespaces usados para los ejemplos:

{{< text bash >}}
$ kubectl delete ns istio-io-health istio-io-health-rewrite
{{< /text >}}
