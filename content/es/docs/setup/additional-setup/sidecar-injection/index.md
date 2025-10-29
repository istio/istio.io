---
title: Instalando el Sidecar
description: Instala el sidecar de Istio en Pods de aplicación automáticamente usando el webhook del inyector de sidecar o manualmente usando la CLI de istioctl.
weight: 45
keywords: [kubernetes,sidecar,sidecar-injection]
aliases:
    - /docs/setup/kubernetes/automatic-sidecar-inject.html
    - /docs/setup/kubernetes/sidecar-injection/
    - /docs/setup/kubernetes/additional-setup/sidecar-injection/
owner: istio/wg-environments-maintainers
test: no
---

## Inyección

Para aprovechar todas las características de Istio, los Pods en la mesh deben estar ejecutando un proxy sidecar de Istio.

Las siguientes secciones describen dos
formas de inyectar el sidecar de Istio en un Pod: habilitando la inyección automática de sidecar de Istio en el Namespace del Pod,
o manualmente usando el comando [`istioctl`](/es/docs/reference/commands/istioctl).

Cuando está habilitada en el Namespace de un Pod, la inyección automática inyecta la configuración del proxy en el momento de creación del Pod usando un admission controller.

La inyección manual modifica directamente la configuración, como deployments, agregando la configuración del proxy en ella.

Si no estás seguro de cuál usar, se recomienda la inyección automática.

### Inyección automática de sidecar

Los sidecars pueden agregarse automáticamente a Pods de Kubernetes aplicables usando un
[mutating webhook admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) proporcionado por Istio.

{{< tip >}}
Mientras que los controladores de admisión están habilitados por defecto, algunas distribuciones de Kubernetes pueden deshabilitarlos. Si este es el caso, sigue las instrucciones para [activar los controladores de admisión](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#how-do-i-turn-on-an-admission-controller).
{{< /tip >}}

Cuando estableces la etiqueta `istio-injection=enabled` en un Namespace y el webhook de inyección está habilitado, cualquier nuevo Pod que se cree en ese Namespace tendrá un sidecar agregado automáticamente.

Ten en cuenta que a diferencia de la inyección manual, la inyección automática ocurre a nivel de Pod. No verás ningún cambio en el deployment en sí. En su lugar, querrás verificar los Pods individuales (a través de `kubectl describe`) para ver el proxy inyectado.

#### Implementando una app

Implementa la app curl. Verifica tanto el deployment como el Pod tienen un solo contenedor.

{{< text bash >}}
$ kubectl apply -f @samples/curl/curl.yaml@
$ kubectl get deployment -o wide
NAME    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
curl    1/1     1            1           12s   curl         curlimages/curl           app=curl
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                    READY   STATUS    RESTARTS   AGE
curl-8f795f47d-hdcgs    1/1     Running   0          42s
{{< /text >}}

Etiqueta el Namespace `default` con `istio-injection=enabled`

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled --overwrite
$ kubectl get namespace -L istio-injection
NAME                 STATUS   AGE     ISTIO-INJECTION
default              Active   5m9s    enabled
...
{{< /text >}}

La inyección ocurre en el momento de la creación del Pod. Mata el Pod en ejecución y verifica que se crea un nuevo Pod con el sidecar inyectado. El Pod original tiene `1/1` contenedores, y el Pod con el sidecar inyectado tiene `2/2` contenedores.

{{< text bash >}}
$ kubectl delete pod -l app=curl
$ kubectl get pod -l app=curl
pod "curl-776b7bcdcd-7hpnk" deleted
NAME                     READY     STATUS        RESTARTS   AGE
curl-776b7bcdcd-7hpnk    1/1       Terminating   0          1m
curl-776b7bcdcd-bhn9m    2/2       Running       0          7s
{{< /text >}}

Ve el estado detallado del Pod inyectado. Deberías ver el contenedor `istio-proxy` inyectado y los volúmenes correspondientes.

{{< text bash >}}
$ kubectl describe pod -l app=curl
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  ...
  Normal  Created    11s   kubelet            Created container istio-init
  Normal  Started    11s   kubelet            Started container istio-init
  ...
  Normal  Created    10s   kubelet            Created container curl
  Normal  Started    10s   kubelet            Started container curl
  ...
  Normal  Created    9s    kubelet            Created container istio-proxy
  Normal  Started    8s    kubelet            Started container istio-proxy
{{< /text >}}

Deshabilita la inyección para el Namespace `default` y verifica que los nuevos Pods no tengan el sidecar.

{{< text bash >}}
$ kubectl label namespace default istio-injection-
$ kubectl delete pod -l app=curl
$ kubectl get pod
namespace/default labeled
pod "curl-776b7bcdcd-bhn9m" deleted
NAME                     READY     STATUS        RESTARTS   AGE
curl-776b7bcdcd-bhn9m    2/2       Terminating   0          2m
curl-776b7bcdcd-gmvnr    1/1       Running       0          2s
{{< /text >}}

#### Controlando la política de inyección

En los ejemplos anteriores, habilitaste y deshabilitaste la inyección a nivel de Namespace. La inyección también puede ser controlada
a nivel de Pod, configurando la etiqueta `sidecar.istio.io/inject` en un Pod:

| Recurso | Etiqueta | Valor habilitado | Valor deshabilitado |
| -------- | ----- | ------------- | -------------- |
| Namespace | `istio-injection` | `enabled` | `disabled` |
| Pod | `sidecar.istio.io/inject` | `"true"` | `"false"` |

Si estás usando [revisions de control plane](/es/docs/setup/upgrade/canary/), las etiquetas de revisión específicas se utilizan en lugar de las etiquetas de revisión.
Por ejemplo, para una revisión llamada `canary`:

| Recurso | Etiqueta habilitada | Etiqueta deshabilitada |
| -------- | ------------- | -------------- |
| Namespace | `istio.io/rev=canary` | `istio-injection=disabled` |
| Pod | `istio.io/rev=canary` | `sidecar.istio.io/inject="false"` |

Si la etiqueta `istio-injection` y la etiqueta `istio.io/rev` están presentes en el mismo Namespace,
la etiqueta `istio-injection` tendrá prioridad.

El inyector está configurado con la siguiente lógica:

1. Si cualquiera de las etiquetas (`istio-injection` o `sidecar.istio.io/inject`) está deshabilitada, el Pod no se inyecta.
1. Si cualquiera de las etiquetas (`istio-injection` o `sidecar.istio.io/inject` o `istio.io/rev`) está habilitada, el Pod se inyecta.
1. Si ninguna etiqueta está establecida, el Pod se inyecta si `.values.sidecarInjectorWebhook.enableNamespacesByDefault` está habilitado. Esto no está habilitado por defecto, por lo que generalmente significa que el Pod no se inyecta.

### Inyección manual de sidecar

Para inyectar manualmente un deployment, usa [`istioctl kube-inject`](/es/docs/reference/commands/istioctl/#istioctl-kube-inject):

{{< text bash >}}
$ istioctl kube-inject -f @samples/curl/curl.yaml@ | kubectl apply -f -
serviceaccount/curl created
service/curl created
deployment.apps/curl created
{{< /text >}}

Por defecto, esto usará la configuración en cluster. Alternativamente, la inyección puede hacerse usando copias locales de la configuración.

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.values}' > inject-values.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

Ejecuta `kube-inject` sobre el archivo de entrada y despliega.

{{< text bash >}}
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --valuesFile inject-values.yaml \
    --filename @samples/curl/curl.yaml@ \
    | kubectl apply -f -
serviceaccount/curl created
service/curl created
deployment.apps/curl created
{{< /text >}}

Verifica que el sidecar se haya inyectado en el Pod curl con `2/2` bajo la columna READY.

{{< text bash >}}
$ kubectl get pod  -l app=curl
NAME                     READY   STATUS    RESTARTS   AGE
curl-64c6f57bc8-f5n4x    2/2     Running   0          24s
{{< /text >}}

## Personalizando la inyección

Generalmente, los Pods se inyectan basándose en el template de inyección de sidecar, configurado en el configmap `istio-sidecar-injector`.
La configuración por Pod está disponible para sobrescribir estas opciones en Pods individuales. Esto se hace agregando un contenedor `istio-proxy`
a tu Pod. La inyección de sidecar tratará cualquier configuración definida aquí como una sobrescritura al template de inyección por defecto.

Debe tomarse precaución al personalizar estos ajustes, ya que esto permite una personalización completa del `Pod`, incluyendo cambios que causan que el contenedor sidecar no funcione correctamente.

Por ejemplo, la siguiente configuración personaliza una variedad de ajustes, incluyendo la reducción de la solicitud de CPU, la adición de un volumen montado, y la adición de un `preStop` hook:

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  containers:
  - name: hello
    image: alpine
  - name: istio-proxy
    image: auto
    resources:
      requests:
        cpu: "100m"
    volumeMounts:
    - mountPath: /etc/certs
      name: certs
    lifecycle:
      preStop:
        exec:
          command: ["curl", "10"]
  volumes:
  - name: certs
    secret:
      secretName: istio-certs
{{< /text >}}

En general, cualquier campo en un Pod puede ser establecido. Sin embargo, debe tomarse precaución con ciertos campos:

* Kubernetes requiere que el campo `image` se establezca antes de que la inyección se ejecute. Aunque puedes establecer una imagen específica para sobrescribir la predeterminada,
  se recomienda establecer el `image` a `auto`, lo que causará que el inyector de sidecar seleccione automáticamente la imagen a utilizar.
* Algunos campos en `Pod` son dependientes de otras configuraciones. Por ejemplo, la solicitud de CPU debe ser menor que el límite de CPU. Si ambos campos no se configuran juntos, el Pod puede fallar al iniciar.
* Los campos `securityContext.RunAsUser` y `securityContext.RunAsGroup` pueden no ser respetados en algunos casos, por ejemplo, cuando se usa el modo `TPROXY`,
  ya que requiere que el sidecar se ejecute como usuario `0`. Sobrescribir estos campos incorrectamente puede causar pérdida de tráfico y debe hacerse con extrema precaución.

{{< warning >}}
Otros admission controllers pueden ejecutarse contra el spec del Pod antes de la inyección de Istio, lo que puede mutar o rechazar la configuración.
Por ejemplo, `LimitRange` puede insertar solicitudes de recursos automáticamente antes de que Istio agregue sus recursos configurados, lo que da como resultado resultados inesperados.
{{< /warning >}}

Además, ciertos campos son configurables por [anotaciones](/es/docs/reference/config/annotations/) en el Pod, aunque se recomienda usar el enfoque anterior para personalizar los ajustes. Debe tomarse precaución con ciertas anotaciones:

* Si `sidecar.istio.io/proxyCPU` está establecido, asegúrate de establecer explícitamente `sidecar.istio.io/proxyCPULimit`. De lo contrario, el límite de CPU del sidecar se establecerá como ilimitado.
* Si `sidecar.istio.io/proxyMemory` está establecido, asegúrate de establecer explícitamente `sidecar.istio.io/proxyMemoryLimit`. De lo contrario, el límite de memoria del sidecar se establecerá como ilimitado.

Por ejemplo, ve los siguientes recursos de anotación incompleta y los ajustes de recursos correspondientes inyectados:

{{< text yaml >}}
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/proxyCPU: "200m"
        sidecar.istio.io/proxyMemoryLimit: "5Gi"
{{< /text >}}

{{< text yaml >}}
spec:
  containers:
  - name: istio-proxy
    resources:
      limits:
        memory: 5Gi
      requests:
        cpu: 200m
        memory: 5Gi
      securityContext:
        allowPrivilegeEscalation: false
{{< /text >}}

### Plantillas personalizadas (experimental)

{{< warning >}}
Esta característica es experimental y está sujeta a cambios, o eliminación, en cualquier momento.
{{< /warning >}}

También se pueden definir plantillas completamente personalizadas durante la instalación.
Por ejemplo, para definir una plantilla personalizada que inyecta la variable de entorno `GREETING` en el contenedor `istio-proxy`:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
spec:
  values:
    sidecarInjectorWebhook:
      templates:
        custom: |
          spec:
            containers:
            - name: istio-proxy
              env:
              - name: GREETING
                value: hello-world
{{< /text >}}

Los Pods, por defecto, usarán el template de inyección `sidecar`, que se crea automáticamente.
Esto puede ser sobrescrito por la anotación `inject.istio.io/templates`.
Por ejemplo, para aplicar el template por defecto y nuestra personalización, puedes establecer `inject.istio.io/templates=sidecar,custom`.

Además del `sidecar`, se proporciona un template `gateway` por defecto para admitir la inyección de proxy en los deployments de Gateway.
