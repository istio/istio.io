---
title: cert-manager
description: Інформація про інтеграцію з cert-manager.
weight: 26
keywords: [integration,cert-manager]
aliases:
  - /docs/tasks/traffic-management/ingress/ingress-certmgr/
  - /docs/examples/advanced-gateways/ingress-certmgr/
owner: istio/wg-environments-maintainers
test: no
---

[cert-manager](https://cert-manager.io/) — це інструмент для автоматизації управління сертифікатами. Його можна інтегрувати зі шлюзами Istio для управління TLS сертифікатами.

## Конфігурація {#configuration}

Ознайомтеся з [документацією з встановлення cert-manager](https://cert-manager.io/docs/installation/kubernetes/) для початку роботи. Ніяких спеціальних змін не потрібно для роботи з Istio.

## Використання {#usage}

### Шлюз Istio {#istio-gateway}

cert-manager можна використовувати для запису секрету в Kubernetes, який потім може бути використаний шлюзом.

1. Для початку налаштуйте ресурс `Issuer`, слідуючи [документації issuer cert-manager](https://cert-manager.io/docs/configuration/). `Issuer` є ресурсом Kubernetes, який представляє центри сертифікації (CA), які можуть генерувати підписані сертифікати, виконуючи запити на підписання сертифікатів. Наприклад, `Issuer` може виглядати так:

    {{< text yaml >}}
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: ca-issuer
      namespace: istio-system
    spec:
      ca:
        secretName: ca-key-pair
    {{< /text >}}

    {{< tip >}}
    Для типу Issuer, ACME, створюється pod і сервіс, які відповідають на запити на підтвердження, щоб перевірити, чи володіє клієнт доменом. Щоб відповісти на ці виклики, точка доступу `http://<YOUR_DOMAIN>/.well-known/acme-challenge/<TOKEN>` повинна бути досяжною. Ця конфігурація може бути специфічною для реалізації.
    {{< /tip >}}

1. Далі налаштуйте ресурс `Certificate`, слідуючи [документації cert-manager](https://cert-manager.io/docs/usage/certificate/). `Certificate` має бути створений в тому ж просторі імен, що і розгортання `istio-ingressgateway`. Наприклад, `Certificate` може виглядати так:

    {{< text yaml >}}
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: ingress-cert
      namespace: istio-system
    spec:
      secretName: ingress-cert
      commonName: my.example.com
      dnsNames:
      - my.example.com
      ...
    {{< /text >}}

1. Після створення сертифіката, ми повинні побачити створений секрет у просторі імен `istio-system`. Це можна потім використовувати в конфігурації `tls` для шлюзу під `credentialName`:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: gateway
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: ingress-cert # Це повинно відповідати secretName сертифіката
        hosts:
        - my.example.com # Це повинно відповідати DNS імені в сертифікаті
    {{< /text >}}

### Kubernetes Ingress {#kubernetes-ingress}

cert-manager забезпечує безпосередню інтеграцію з Kubernetes Ingress, конфігуруючи [анотацію на обʼєкті Ingress](https://cert-manager.io/docs/usage/ingress/). Якщо використовується цей метод, Ingress має розміщуватись в тому ж просторі імен, що і розгортання `istio-ingressgateway`, оскільки секрети читатимуться лише в тому ж просторі імен.

Альтернативно, можна створити `Certificate`, як описано в [Шлюз Istio](#istio-gateway), а потім використати його в обʼєкті `Ingress`:

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - host: my.example.com
    http: ...
  tls:
  - hosts:
    - my.example.com # Це повинно відповідати DNS імені в сертифікаті
    secretName: ingress-cert # Це повинно відповідати secretName сертифіката
{{< /text >}}
