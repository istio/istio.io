---
title: Problemas de inyección de sidecar
description: Resuelve problemas comunes con el uso que hace Istio de los webhooks de Kubernetes para la inyección automática de sidecar.
force_inline_toc: true
weight: 40
aliases:
  - /docs/ops/troubleshooting/injection
owner: istio/wg-user-experience-maintainers
test: n/a
---

## El resultado de la inyección de sidecar no fue el esperado {#the-result-of-sidecar-injection-was-not-what-i-expected}

Esto incluye tanto un sidecar inyectado cuando no se esperaba como la ausencia
de un sidecar inyectado cuando sí se esperaba.

1. Asegúrate de que tu pod no esté en el namespace `kube-system` o `kube-public`.
   La inyección automática de sidecar se ignora para los pods de estos namespaces.

1. Asegúrate de que tu pod no tenga `hostNetwork: true` en su especificación.
   La inyección automática de sidecar se ignora para los pods que están en la red del host.

    El modelo de sidecar asume que los cambios de iptables que Envoy necesita para interceptar
    el tráfico se aplican dentro del pod. Para los pods en la red del host, esta suposición no se cumple,
    y esto puede provocar fallos de enrutamiento a nivel del host.

1. Revisa el `namespaceSelector` del webhook para determinar si el
   webhook funciona como opt-in (inclusión explícita) u opt-out (exclusión explícita) para el namespace de destino.

    El `namespaceSelector` para opt-in tendrá el siguiente aspecto:

    {{< text bash yaml >}}
    $ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep "namespaceSelector:" -A5
      namespaceSelector:
        matchLabels:
          istio-injection: enabled
      rules:
      - apiGroups:
        - ""
    {{< /text >}}

    El webhook de inyección se invocará para los pods creados
    en namespaces con la etiqueta `istio-injection=enabled`.

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d       enabled
    istio-system   Active    3d
    kube-public    Active    18d
    kube-system    Active    18d
    {{< /text >}}

    El `namespaceSelector` para opt-out tendrá el siguiente aspecto:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep "namespaceSelector:" -A5
      namespaceSelector:
        matchExpressions:
        - key: istio-injection
          operator: NotIn
          values:
          - disabled
      rules:
      - apiGroups:
        - ""
    {{< /text >}}

    El webhook de inyección se invocará para los pods creados en namespaces
    sin la etiqueta `istio-injection=disabled`.

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d
    istio-system   Active    3d        disabled
    kube-public    Active    18d       disabled
    kube-system    Active    18d       disabled
    {{< /text >}}

    Verifica que el namespace del pod de la aplicación tenga la etiqueta correcta y vuelve a etiquetarlo si es necesario, p. ej.

    {{< text bash >}}
    $ kubectl label namespace istio-system istio-injection=disabled --overwrite
    {{< /text >}}

    (repite esto para todos los namespaces en los que el webhook de inyección deba invocarse para los pods nuevos)

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    {{< /text >}}

1. Revisa la política predeterminada

    Revisa la política de inyección predeterminada en el `istio-sidecar-injector configmap`.

    {{< text bash yaml >}}
    $ kubectl -n istio-system get configmap istio-sidecar-injector -o jsonpath='{.data.config}' | grep policy:
    policy: enabled
    {{< /text >}}

    Los valores de política permitidos son `disabled` y `enabled`. La política predeterminada
    solo se aplica si el `namespaceSelector` del webhook coincide con el namespace
    de destino. Una política no reconocida hace que la inyección se deshabilite por completo.

1. Revisa la etiqueta de anulación por pod

    La política predeterminada se puede anular con la
    etiqueta `sidecar.istio.io/inject` en los _metadatos de la especificación de la plantilla del pod_.
    Los metadatos del Deployment se ignoran. Un valor de etiqueta
    de `true` fuerza la inyección del sidecar, mientras que un valor de
    `false` fuerza que el sidecar _no_ se inyecte.

    La siguiente etiqueta anula cualquier `policy` predeterminada
    para forzar la inyección del sidecar:

    {{< text bash yaml >}}
    $ kubectl get deployment curl -o yaml | grep "sidecar.istio.io/inject:" -B4
    template:
      metadata:
        labels:
          app: curl
          sidecar.istio.io/inject: "true"
    {{< /text >}}

## No se puede crear ningún pod {#pods-cannot-be-created-at-all}

Ejecuta `kubectl describe -n namespace deployment name` en el Deployment del pod
que falla. Los fallos al invocar el webhook de inyección
normalmente quedan registrados en el registro de eventos.

### Errores relacionados con certificados x509 {#x509-certificate-related-errors}

{{< text plain >}}
Warning  FailedCreate  3m (x17 over 8m)  replicaset-controller  Error creating: Internal error occurred: \
    failed calling admission webhook "sidecar-injector.istio.io": Post https://istiod.istio-system.svc:443/inject: \
    x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying \
    to verify candidate authority certificate "Kubernetes.cluster.local")
{{< /text >}}

Los errores `x509: certificate signed by unknown authority` normalmente
se deben a un `caBundle` vacío en la configuración del webhook.

Verifica que el `caBundle` de la `mutatingwebhookconfiguration` coincida con el
   certificado raíz montado en el pod de `istiod`.

{{< text bash >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
$ kubectl -n istio-system get configmap istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | base64 -w 0 | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
{{< /text >}}

Los certificados de CA deben coincidir. Si no coinciden, reinicia los
pods de istiod.

{{< text bash >}}
$ kubectl -n istio-system patch deployment istiod \
    -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
deployment.extensions "istiod" patched
{{< /text >}}

### Errores en el estado del Deployment {#errors-in-deployment-status}

Cuando la inyección automática de sidecar está habilitada para un pod y la inyección falla por cualquier motivo, la creación del pod
también falla. En esos casos, puedes revisar el estado del Deployment del pod para identificar el error. Los errores
también aparecen en los eventos del namespace asociado al Deployment.

Por ejemplo, si el pod del control plane `istiod` no estaba en ejecución cuando intentaste desplegar tu pod, los eventos mostrarían el siguiente error:

{{< text bash >}}
$ kubectl get events -n curl
...
23m Normal   SuccessfulCreate replicaset/curl-9454cc476   Created pod: curl-9454cc476-khp45
22m Warning  FailedCreate     replicaset/curl-9454cc476   Error creating: Internal error occurred: failed calling webhook "namespace.sidecar-injector.istio.io": failed to call webhook: Post "https://istiod.istio-system.svc:443/inject?timeout=10s": dial tcp 10.96.44.51:443: connect: connection refused
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get pod -lapp=istiod
NAME                            READY     STATUS    RESTARTS   AGE
istiod-7d46d8d9db-jz2mh         1/1       Running     0         2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istiod
NAME           ENDPOINTS                                                  AGE
istiod   10.244.2.8:15012,10.244.2.8:15010,10.244.2.8:15017 + 1 more...   3h18m
{{< /text >}}

Si el pod o los endpoints de istiod no están listos, revisa los logs y el estado del pod
en busca de cualquier indicio de por qué el pod del webhook no logra iniciarse y
servir tráfico.

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done


$ for pod in $(kubectl -n istio-system get pod -l app=istiod -o name); do \
kubectl -n istio-system describe ${pod}; \
done
$
{{< /text >}}

## La inyección automática de sidecar falla si el servidor de API de Kubernetes tiene configuración de proxy {#automatic-sidecar-injection-fails-if-the-kubernetes-api-server-has-proxy-settings}

Cuando el servidor de API de Kubernetes incluye configuración de proxy como:

{{< text yaml >}}
env:
  - name: http_proxy
    value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
    value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
    value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
{{< /text >}}

Con esta configuración, la inyección de sidecar falla. El único log de fallo relacionado se encuentra en el log de `kube-apiserver`:

{{< text plain >}}
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
{{< /text >}}

Asegúrate de que ni los CIDR de pods ni los de services pasen por el proxy según las variables `*_proxy`. Revisa los archivos y los logs de `kube-apiserver` para verificar la configuración y comprobar si alguna solicitud pasa por el proxy.

Una solución alternativa es eliminar la configuración de proxy del manifiesto de `kube-apiserver`; otra es incluir `istio-sidecar-injector.istio-system.svc` o `.svc` en el valor de `no_proxy`. Asegúrate de reiniciar `kube-apiserver` después de aplicar cualquiera de las dos.

Se abrió un [problema](https://github.com/kubernetes/kubeadm/issues/666) en Kubernetes relacionado con esto, que ya se ha cerrado.
[https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)

## Limitaciones al usar Tcpdump en pods {#limitations-for-using-tcpdump-in-pods}

Tcpdump no funciona en el pod del sidecar: el contenedor no se ejecuta como root. Sin embargo, cualquier otro contenedor del mismo pod verá todos los paquetes, ya que el
namespace de red es compartido. `iptables` también verá la configuración de todo el pod.

La comunicación entre Envoy y la aplicación ocurre en 127.0.0.1 y no está cifrada.

## El clúster no se reduce automáticamente {#cluster-is-not-scaled-down-automatically}

Debido a que el contenedor del sidecar monta un volumen de almacenamiento local, el
escalador automático de nodos no puede desalojar los nodos que tienen pods inyectados. Este es
un [problema conocido](https://github.com/kubernetes/autoscaler/issues/3947). La solución alternativa es
agregar la anotación de pod `"cluster-autoscaler.kubernetes.io/safe-to-evict":
"true"` a los pods inyectados.

## El pod o los contenedores se inician con problemas de red si istio-proxy no está listo {#pod-or-containers-start-with-network-issues-if-istio-proxy-is-not-ready}

Muchas aplicaciones ejecutan comandos o comprobaciones durante el inicio que requieren conectividad de red. Esto puede hacer que los contenedores de la aplicación se bloqueen o se reinicien si el contenedor del sidecar `istio-proxy` no está listo.

Para evitarlo, establece `holdApplicationUntilProxyStarts` en `true`. Esto hace que el inyector de sidecar inyecte el sidecar al principio de la lista de contenedores del pod y lo configure para bloquear el inicio de todos los demás contenedores hasta que el proxy esté listo.

Esto se puede agregar como opción de configuración global:

{{< text yaml >}}
values.global.proxy.holdApplicationUntilProxyStarts: true
{{< /text >}}

o como anotación de pod:

{{< text yaml >}}
proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
{{< /text >}}
