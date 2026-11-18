---
title: Problemas de validación de configuración
description: Describe cómo resolver problemas de validación de configuración.
force_inline_toc: true
weight: 50
aliases:
    - /help/ops/setup/validation
    - /help/ops/troubleshooting/validation
    - /docs/ops/troubleshooting/validation
owner: istio/wg-user-experience-maintainers
test: no
---

## Se rechaza una configuración aparentemente válida {#seemingly-valid-configuration-is-rejected}

Usa [istioctl validate -f](/es/docs/reference/commands/istioctl/#istioctl-validate) e [istioctl analyze](/es/docs/reference/commands/istioctl/#istioctl-analyze) para entender mejor por qué se rechaza la configuración. Usa una CLI de _istioctl_ con una versión similar a la del control plane.

Los problemas de configuración que se reportan con más frecuencia son errores de indentación de YAML y de notación de arrays (`-`).

Verifica manualmente que tu configuración sea correcta y consulta la
[referencia de la API de Istio](/es/docs/reference/config) cuando
sea necesario.

## Se acepta una configuración no válida {#invalid-configuration-is-accepted}

Verifica que exista y sea correcta una `validatingwebhookconfiguration` llamada `istio-validator-` seguida de
`<revision>-`, si no es la revisión predeterminada, y luego del namespace del sistema de Istio
(p. ej., `istio-validator-myrev-istio-system`).
Los campos `apiVersion`, `apiGroup` y `resource` de la
configuración no válida deberían aparecer en la sección `webhooks` de la `validatingwebhookconfiguration`.

{{< text bash yaml >}}
$ kubectl get validatingwebhookconfiguration istio-validator-istio-system -o yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  labels:
    app: istiod
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio: istiod
    istio.io/rev: default
    operator.istio.io/component: Pilot
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: unknown
    release: istio
  name: istio-validator-istio-system
  resourceVersion: "615569"
  uid: 112fed62-93e7-41c9-8cb1-b2665f392dd7
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    # caBundle should be non-empty. This is periodically (re)patched
    # every second by the webhook service using the ca-cert
    # from the mounted service account secret.
    caBundle: LS0t...
    # service corresponds to the Kubernetes service that implements the webhook
    service:
      name: istiod
      namespace: istio-system
      path: /validate
      port: 443
  failurePolicy: Fail
  matchPolicy: Equivalent
  name: rev.validation.istio.io
  namespaceSelector: {}
  objectSelector:
    matchExpressions:
    - key: istio.io/rev
      operator: In
      values:
      - default
  rules:
  - apiGroups:
    - security.istio.io
    - networking.istio.io
    - telemetry.istio.io
    - extensions.istio.io
    apiVersions:
    - '*'
    operations:
    - CREATE
    - UPDATE
    resources:
    - '*'
    scope: '*'
  sideEffects: None
  timeoutSeconds: 10
{{< /text >}}

Si el webhook `istio-validator-` no existe, verifica que
la opción de instalación `global.configValidation` esté
establecida en `true`.

La configuración de validación es fail-close. Si la
configuración existe y tiene el alcance correcto, el webhook se
invocará. Si falta el `caBundle`, el certificado no es válido o hay un problema de conectividad
de red, se producirá un mensaje de error al crear o actualizar
el recurso. Si no ves ningún mensaje de error, el webhook
no se invocó y la configuración del webhook es válida, tu clúster está
mal configurado.

## La creación de la configuración falla con errores de certificado x509 {#creating-configuration-fails-with-x509-certificate-errors}

Los errores relacionados con `x509: certificate signed by unknown authority`
normalmente se deben a un `caBundle` vacío en la configuración
del webhook. Verifica que no esté vacío (consulta [verificar la configuración
del webhook](#invalid-configuration-is-accepted)). Istio reconcilia deliberadamente la configuración del webhook
usando el `configmap` `istio-validation` y el certificado raíz.

1. Verifica que los pods de `istiod` estén en ejecución:

    {{< text bash >}}
    $  kubectl -n istio-system get pod -lapp=istiod
    NAME                            READY     STATUS    RESTARTS   AGE
    istiod-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

1. Revisa los logs del pod en busca de errores. Si falla la aplicación del patch al
       `caBundle`, debería mostrarse un error.

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

1. Si falló la aplicación del patch, verifica la configuración de RBAC de Istiod:

    {{< text bash yaml >}}
    $ kubectl get clusterrole istiod-istio-system -o yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
      name: istiod-istio-system
    rules:
    - apiGroups:
      - admissionregistration.k8s.io
      resources:
      - validatingwebhookconfigurations
      verbs:
      - '*'
    {{< /text >}}

    Istio necesita acceso de escritura a `validatingwebhookconfigurations` para
    crear y actualizar la `validatingwebhookconfiguration`.

## La creación de la configuración falla con errores `no such hosts` o `no endpoints available` {#creating-configuration-fails-with-no-such-hosts-or-no-endpoints-available-errors}

La validación es fail-close. Si el pod de `istiod` no está listo,
no se puede crear ni actualizar la configuración. En esos casos, verás
un error sobre `no endpoints available`.

Verifica que los pods de `istiod` estén en ejecución y que los endpoints estén listos.

{{< text bash >}}
$  kubectl -n istio-system get pod -lapp=istiod
NAME                            READY     STATUS    RESTARTS   AGE
istiod-5dbbbdb746-d676g   1/1       Running   0          2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istiod
NAME           ENDPOINTS                          AGE
istiod         10.48.6.108:15014,10.48.6.108:443   3d
{{< /text >}}

Si los pods o los endpoints no están listos, revisa los logs y el
estado del pod en busca de cualquier indicio de por qué el pod del webhook no logra iniciarse
y servir tráfico.

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done
{{< /text >}}

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}
