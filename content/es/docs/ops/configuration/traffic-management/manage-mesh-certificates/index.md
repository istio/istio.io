---
title: Gestión de certificados dentro de la mesh
linktitle: Gestión de certificados dentro de la mesh
description: Cómo configurar los certificados dentro de tu mesh.
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers,istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate experimental >}}

Muchos usuarios necesitan gestionar los tipos de certificados que se usan en su entorno. Por ejemplo,
algunos usuarios necesitan usar criptografía de curva elíptica (ECC), mientras que otros pueden necesitar
una longitud en bits mayor para los certificados RSA. Configurar los certificados en tu entorno puede ser
una tarea abrumadora para la mayoría de los usuarios.

Este documento está pensado únicamente para la comunicación dentro de la mesh. Para gestionar los certificados de
tu Gateway, consulta el documento [Gateways seguros](/es/docs/tasks/traffic-management/ingress/secure-ingress/).
Para gestionar la CA que usa istiod para generar los certificados de los workloads, consulta
el documento [Conectar certificados de CA](/es/docs/tasks/security/cert-management/plugin-ca-cert/).

## istiod

Cuando Istio se instala sin un certificado de CA raíz, istiod genera un certificado de CA
autofirmado con RSA 2048.

Para cambiar la longitud en bits del certificado de CA autofirmado, debes modificar el manifiesto de IstioOperator que se pasa a
`istioctl` o el archivo de valores que se usa durante la instalación con Helm del chart [istio-discovery]({{< github_tree >}}/manifests/charts/istio-control/istio-discovery).

{{< tip >}}
Aunque hay muchas variables de entorno que se pueden cambiar en
[pilot-discovery](/es/docs/reference/commands/pilot-discovery/), este documento solo
describe algunas de ellas.
{{< /tip >}}

{{< tabset category-name="certificates" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      env:
        CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
pilot:
  env:
    CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Sidecars

Como los sidecars gestionan sus propios certificados para la comunicación dentro de la mesh,
son responsables de gestionar sus claves privadas y las solicitudes de firma de certificado (CSR) que generan. Es necesario
modificar el inyector de sidecars para que inyecte las variables de entorno que se usarán con
este fin.

{{< tip >}}
Aunque hay muchas variables de entorno que se pueden cambiar en
[pilot-agent](/es/docs/reference/commands/pilot-agent/), este documento solo
describe algunas de ellas.
{{< /tip >}}

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Annotation" category-value="annotation" >}}

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
    spec:
      ...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Algoritmo de firma {#signature-algorithm}

Por defecto, los sidecars crean certificados RSA. Si quieres cambiarlo a
ECC, debes configurar `ECC_SIGNATURE_ALGORITHM` con el valor `ECDSA`.

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ECC_SIGNATURE_ALGORITHM: "ECDSA"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ECC_SIGNATURE_ALGORITHM: "ECDSA"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Mediante `ECC_CURVE` solo se admiten P256 y P384.

Si prefieres mantener los algoritmos de firma RSA y quieres modificar el tamaño de la clave RSA,
puedes cambiar el valor de `WORKLOAD_RSA_KEY_SIZE`.
