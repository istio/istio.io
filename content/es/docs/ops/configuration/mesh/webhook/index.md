---
title: Visión General de Dynamic Admission Webhooks
description: Proporciona una visión general de el uso de webhooks de Kubernetes por parte de Istio y los problemas relacionados que pueden surgir.
weight: 10
aliases:
  - /help/ops/setup/webhook
  - /docs/ops/setup/webhook
owner: istio/wg-user-experience-maintainers
test: no
---

De [los mecanismos de validating y mutating webhook de Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/):

{{< tip >}}
Los admission webhooks son callbacks HTTP que reciben solicitudes de admisión
y hacen algo con ellas. Puedes definir dos tipos de admission
webhooks, validating admission webhook y mutating admission
webhook. Con validating admission webhooks, puedes rechazar solicitudes
para hacer cumplir políticas de admisión personalizadas. Con mutating admission
webhooks, puedes cambiar solicitudes para hacer cumplir valores por defecto personalizados.
{{< /tip >}}

Istio usa `ValidatingAdmissionWebhooks` para validar configuración de Istio
y `MutatingAdmissionWebhooks` para inyectar automáticamente el sidecar proxy en pods de usuario.

Las guías de configuración de webhook asumen familiaridad general con Kubernetes
Dynamic Admission Webhooks. Consulta las referencias de API de Kubernetes para
documentación detallada de la [Configuración de Mutating Webhook](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#mutatingwebhookconfiguration-v1-admissionregistration-k8s-io) y [Configuración de Validating Webhook](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#validatingwebhookconfiguration-v1-admissionregistration-k8s-io).

## Verificar prerrequisitos de dynamic admission webhook

Ve las [instrucciones de configuración de plataforma](/es/docs/setup/platform-setup/)
para instrucciones de configuración específicas del proveedor de Kubernetes. Los webhooks no
funcionarán correctamente si el cluster está mal configurado. Puedes seguir
estos pasos una vez que el cluster haya sido configurado y los webhooks dinámicos
y características dependientes no estén funcionando correctamente.

1. Verifica que estés usando una [versión soportada](/es/docs/releases/supported-releases#support-status-of-istio-releases) ({{< supported_kubernetes_versions >}}) de
   [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) y del servidor de Kubernetes:

    {{< text bash >}}
    $ kubectl version --short
    Client Version: v1.29.0
    Server Version: v1.29.1
    {{< /text >}}

1. `admissionregistration.k8s.io/v1` debe estar habilitado

    {{< text bash >}}
    $ kubectl api-versions | grep admissionregistration.k8s.io/v1
    admissionregistration.k8s.io/v1
    {{< /text >}}

1. Verifica que los plugins `MutatingAdmissionWebhook` y `ValidatingAdmissionWebhook` estén
   listados en el `kube-apiserver --enable-admission-plugins`. El acceso
   a esta bandera es [específico del proveedor](/es/docs/setup/platform-setup/).

1. Verifica que el kube-apiserver de Kubernetes tenga conectividad de red al
   pod webhook. Por ejemplo, configuraciones incorrectas de `http_proxy` pueden interferir
   con la operación del api-server (ve problemas relacionados
   [aquí](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)
   y [aquí](https://github.com/kubernetes/kubeadm/issues/666) para más información).
