---
title: ISTIO-SECURITY-2022-002
subtitle: Boletín de seguridad
description: Escalada de privilegios en la API Gateway de Kubernetes.
cves: [CVE-2022-21701]
cvss: "4.7"
vector: "AV:N/AC:L/PR:H/UI:N/S:U/C:L/I:L/A:L"
releases: ["1.12.0 a 1.12.1"]
publishdate: 2022-01-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-21701

Las versiones 1.12.0 y 1.12.1 de Istio tienen una vulnerabilidad de escalada de privilegios. Un usuario con permiso `CREATE` sobre objetos `gateways.gateway.networking.k8s.io` podría llegar a crear otros recursos para los que carece de permiso, como objetos `Pod`.

## ¿Estoy afectado?

La vulnerabilidad afecta únicamente a una funcionalidad en fase alfa, la [API Gateway de Kubernetes](/docs/tasks/traffic-management/ingress/gateway-api/). El tipo `Gateway` de Istio (`gateways.networking.istio.io`) queda fuera del alcance de esta vulnerabilidad.

Tu clúster podría estar afectado si se cumplen estas condiciones:

* Tienes instalado el CRD de Gateway de Kubernetes. Puedes comprobarlo con `kubectl get crd gateways.gateway.networking.k8s.io`.
* Istiod tiene habilitado el controlador de despliegues de Gateway API. La variable de entorno `PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER` tiene el valor `true` de forma predeterminada.
* Usuarios no confiables tienen el permiso `CREATE` sobre objetos `gateways.gateway.networking.k8s.io`.

## Medidas alternativas

Si no puedes actualizar, cualquiera de estas medidas evita la vulnerabilidad:

* Elimina la `CustomResourceDefinition` de `gateways.gateway.networking.k8s.io`.
* Configura la variable de entorno `PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER=false` en Istiod.
* Retira a los usuarios no confiables el permiso `CREATE` sobre objetos `gateways.gateway.networking.k8s.io`.

## Agradecimientos

Agradecemos a Anthony Weems.
