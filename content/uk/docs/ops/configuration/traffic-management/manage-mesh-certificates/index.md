---
title: Керування сертифікатами всередині Mesh
linktitle: Керування сертифікатами всередині Mesh
description: Як налаштувати сертифікати всередині вашого Mesh.
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers,istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate experimental >}}

Багато користувачів потребують керування типами сертифікатів, які використовуються в їх середовищі. Наприклад, деякі користувачі потребують використання Elliptical Curve Cryptography (ECC), тоді як інші можуть потребувати використання сертифікатів з більшою довжиною ключа для RSA. Налаштування сертифікатів у вашому середовищі може бути складним завданням для більшості користувачів.

Цей документ призначений тільки для комунікації всередині Mesh. Для керування сертифікатами на вашому Gateway, див. документ [Захист Gateways](/docs/tasks/traffic-management/ingress/secure-ingress/). Для керування CA, який використовує istiod для генерації сертифікатів робочих навантажень, див. документ [Підключення сертифікатів CA](/docs/tasks/security/cert-management/plugin-ca-cert/).

## istiod {#istiod}

Коли Istio встановлюється без кореневого сертифіката CA, istiod згенерує самопідписний сертифікат CA, використовуючи RSA 2048.

Щоб змінити довжину ключа самопідпианого сертифіката CA, потрібно змінити або маніфест IstioOperator, наданий для `istioctl`, або файл значень, що використовувався під час установки Helm для чарту [istio-discovery]({{< github_tree >}}/manifests/charts/istio-control/istio-discovery).

{{< tip >}}
Хоча є багато змінних середовища, які можна змінювати для [pilot-discovery](/docs/reference/commands/pilot-discovery/), цей документ буде описувати лише деякі з них.
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

## Sidecars {#sidecars}

Оскільки sidecars управляють своїми власними сертифікатами для комунікації всередині Mesh, sidecars відповідають за управління своїми приватними ключами та згенерованими Запитами на Підпис Сертифікатів (CSR). Необхідно змінити інжектор sidecar, щоб вставити змінні середовища, які будуть використовуватися для цієї мети.

{{< tip >}}
Хоча є багато змінних середовища, які можна змінювати для [pilot-agent](/docs/reference/commands/pilot-agent/), цей документ буде описувати лише деякі з них.
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

### Алгоритм підпису {#signature-algorithm}

Стандартно sidecars створюють RSA сертифікати. Якщо ви хочете змінити це на
ECC, потрібно встановити `ECC_SIGNATURE_ALGORITHM` на `ECDSA`.

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

Тільки P256 та P384 підтримуються через `ECC_CURVE`.

Якщо ви віддаєте перевагу зберігати RSA алгоритми підпису і хочете змінити розмір ключа RSA, можете змінити значення `WORKLOAD_RSA_KEY_SIZE`.
