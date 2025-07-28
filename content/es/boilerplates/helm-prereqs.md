---
---
## Prerrequisitos

1. Realiza cualquier [configuración específica de la plataforma](/es/docs/setup/platform-setup/) necesaria.

1. Comprueba los [Requisitos para Pods y Servicios](/es/docs/ops/deployment/application-requirements/).

1. [Instala el último cliente de Helm](https://helm.sh/docs/intro/install/). Las versiones de Helm lanzadas antes de la [versión de Istio más antigua actualmente compatible](docs/releases/supported-releases/#support-status-of-istio-releases) no están probadas, no son compatibles ni se recomiendan.

1. Configura el repositorio de Helm:

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}
