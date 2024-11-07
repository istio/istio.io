---
title: Інтеграція з власним ЦС за допомогою Kubernetes CSR
description: Показує, як використовувати власний центр сертифікації (який інтегрується з Kubernetes CSR API) для надання сертифікатів робочого навантаження Istio.
weight: 100
keywords: [security,certificate]
aliases:
    - /uk/docs/tasks/security/custom-ca-k8s/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---

{{< boilerplate experimental >}}

Ця функція вимагає версії Kubernetes >= 1.18.

Це завдання показує, як забезпечити сертифікати робочого навантаження використовуючи власний центр сертифікації, який інтегрується з [API Kubernetes CSR](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/). Різні робочі навантаження можуть отримувати свої сертифікати, підписані різними підписувачами сертифікатів. Кожен підписувач сертифікатів фактично є окремим CA. Очікується, що робочі навантаження, чиї сертифікати видані тим самим підписувачем, можуть взаємодіяти через mTLS, тоді як робочі навантаження, підписані різними підписувачами, не можуть.

Ця функція використовує [Chiron](/blog/2019/dns-cert/), легкий компонент, повʼязаний з Istiod, який підписує сертифікати за допомогою API Kubernetes CSR.

Для цього прикладу ми використовуємо [open-source cert-manager](https://cert-manager.io). Cert-manager додав [експериментальну підтримку Kubernetes `CertificateSigningRequests`](https://cert-manager.io/docs/usage/kube-csr/) починаючи з версії 1.4.

## Розгортання власного контролера ЦС у кластері Kubernetes {#deploy-custom-ca-controller-in-the-kubernetes-cluster}

1. Розгорніть cert-manager дотримуючись настанов з [інструкції зі встановлення](https://cert-manager.io/docs/installation/).

    {{< warning >}}
    Переконайтеся, що ви ввімкнули функціональну можливість: `--feature-gates=ExperimentalCertificateSigningRequestControllers=true`
    {{< /warning >}}

    {{< text bash >}}
    $ helm repo add jetstack https://charts.jetstack.io
    $ helm repo update
    $ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set featureGates="ExperimentalCertificateSigningRequestControllers=true" --set installCRDs=true
    {{< /text >}}

2. Створіть трьох самопідписних кластерних емітентів `istio-system`, `foo` і `bar` для cert-manager. Зауваження: Також можна використовувати емітенти просторів імен та інші типи емітентів.

    {{< text bash >}}
    $ cat <<EOF > ./selfsigned-issuer.yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-bar-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: bar-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: bar
      secretName: bar-ca-selfsigned
      issuerRef:
        name: selfsigned-bar-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: bar
    spec:
      ca:
        secretName: bar-ca-selfsigned
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-foo-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: foo-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: foo
      secretName: foo-ca-selfsigned
      issuerRef:
        name: selfsigned-foo-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: foo
    spec:
      ca:
        secretName: foo-ca-selfsigned
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-istio-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: istio-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: istio-system
      secretName: istio-ca-selfsigned
      issuerRef:
        name: selfsigned-istio-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: istio-system
    spec:
      ca:
        secretName: istio-ca-selfsigned
    EOF
    $ kubectl apply -f ./selfsigned-issuer.yaml
    {{< /text >}}

## Перевірте, що для кожного кластерного емітента створені секрети.{#verify-secrets-are-created-for-each-cluster-issuer}

{{< text bash >}}
$ kubectl get secret -n cert-manager -l controller.cert-manager.io/fao=true
NAME                  TYPE                DATA   AGE
bar-ca-selfsigned     kubernetes.io/tls   3      3m36s
foo-ca-selfsigned     kubernetes.io/tls   3      3m36s
istio-ca-selfsigned   kubernetes.io/tls   3      3m38s
{{< /text >}}

## Експортуйте кореневі сертифікати для кожного кластерного емітента {#export-root-certificates-for-each-cluster-issuer}

{{< text bash >}}
$ export ISTIOCA=$(kubectl get clusterissuers istio-system -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
$ export FOOCA=$(kubectl get clusterissuers foo -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
$ export BARCA=$(kubectl get clusterissuers bar -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
{{< /text >}}

## Розгортання Istio з інформацією стандартного підписувача сертифікатів {#deploy-istio-with-default-cert-signer-info}

1. Розгорніть Istio у кластері за допомогою `istioctl` з наступною конфігурацією. Змінна `ISTIO_META_CERT_SIGNER` є стандартним підписувачем сертифікатів для робочих навантажень.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        pilot:
          env:
            EXTERNAL_CA: ISTIOD_RA_KUBERNETES_API
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_META_CERT_SIGNER: istio-system
        caCertificates:
        - pem: |
    $ISTIOCA
          certSigners:
          - clusterissuers.cert-manager.io/istio-system
        - pem: |
    $FOOCA
          certSigners:
          - clusterissuers.cert-manager.io/foo
        - pem: |
    $BARCA
          certSigners:
          - clusterissuers.cert-manager.io/bar
      components:
        pilot:
          k8s:
            env:
            - name: CERT_SIGNER_DOMAIN
              value: clusterissuers.cert-manager.io
            - name: PILOT_CERT_PROVIDER
              value: k8s.io/clusterissuers.cert-manager.io/istio-system
            overlays:
              - kind: ClusterRole
                name: istiod-clusterrole-istio-system
                patches:
                  - path: rules[-1]
                    value: |
                      apiGroups:
                      - certificates.k8s.io
                      resourceNames:
                      - clusterissuers.cert-manager.io/foo
                      - clusterissuers.cert-manager.io/bar
                      - clusterissuers.cert-manager.io/istio-system
                      resources:
                      - signers
                      verbs:
                      - approve
    EOF
    $ istioctl install --skip-confirmation -f ./istio.yaml
    {{< /text >}}

2. Створіть простори імен `bar` та `foo`.

    {{< text bash >}}
    $ kubectl create ns bar
    $ kubectl create ns foo
    {{< /text >}}

3. Розгорніть файл `proxyconfig-bar.yaml` у просторі імен `bar`, щоб визначити сертифікат підписувача для робочих навантажень у просторі імен `bar`.

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-bar.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: barpc
      namespace: bar
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: bar
    EOF
    $ kubectl apply  -f ./proxyconfig-bar.yaml
    {{< /text >}}

4. Розгорніть файл `proxyconfig-foo.yaml` у просторі імен `foo`, щоб визначити сертифікат підписувача для робочих навантажень у просторі імен `foo`.

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-foo.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: foopc
      namespace: foo
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: foo
    EOF
    $ kubectl apply  -f ./proxyconfig-foo.yaml
    {{< /text >}}

5. Розгорніть демонстраційні застосунки `httpbin` та `curl` у просторах імен `foo` і `bar`.

    {{< text bash >}}
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl label ns bar istio-injection=enabled
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n foo
    $ kubectl apply -f samples/curl/curl.yaml -n foo
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n bar
    {{< /text >}}

## Перевірка мережевої взаємодії між `httpbin` і `curl` у межах одного простору імен {#verify-the-network-connectivity-between-httpbin-and-curl-within-the-same-namespace}

Коли робочі навантаження розгорнуті, вони надсилають запити CSR з відповідною інформацією про підписувача. Istiod пересилає запит CSR до власного центру сертифікації користувача для підпису. Власний CA використовує відповідного кластерного емітента для підпису сертифіката. Робочі навантаження у просторі імен `foo` використовують кластерних емітентів `foo`, а робочі навантаження у просторі імен `bar` використовують кластерних емітентів `bar`. Щоб перевірити, що сертифікати дійсно підписані правильними кластерними емітентами, можна перевірити, чи можуть робочі навантаження в одному просторі імен спілкуватися між собою, тоді як робочі навантаження з різних просторів імен не можуть.

1. Вкажіть в змінну середовища `CURL_POD_FOO` імʼя podʼа `curl`.

    {{< text bash >}}
    $ export CURL_POD_FOO=$(kubectl get pod -n foo -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. Перевірте мережеве зʼєднання між сервісом `curl` та `httpbin` в просторі імен `foo`.

    {{< text bash >}}
    $ kubectl exec "$CURL_POD_FOO" -n foo -c curl -- curl http://httpbin.foo:8000/html
    <!DOCTYPE html>
    <html>
      <head>
      </head>
      <body>
          <h1>Herman Melville - Moby-Dick</h1>

          <div>
            <p>
              Availing himself of the mild...
            </p>
          </div>
      </body>
     {{< /text >}}

1. Перевірте мережеве зʼєднання між сервісами `curl` у просторі імен `foo` та `httpbin` у просторі імен `bar`.

    {{< text bash >}}
    $ kubectl exec "$CURL_POD_FOO" -n foo -c curl -- curl http://httpbin.bar:8000/html
    upstream connect error or disconnect/reset before headers. reset reason: connection failure, transport failure reason: TLS error: 268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED
    {{< /text >}}

## Очищення {#cleanup}

* Видаліть простори імен та видаліть Istio і cert-manager:

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ istioctl uninstall --purge -y
    $ helm delete -n cert-manager cert-manager
    $ kubectl delete ns istio-system cert-manager
    $ unset ISTIOCA FOOCA BARCA
    $ rm -rf istio.yaml proxyconfig-foo.yaml proxyconfig-bar.yaml selfsigned-issuer.yaml
    {{< /text >}}

## Причини використання цієї функції {#reasons-to-use-this-feature}

* Інтеграція власного CA — Завдяки вказівці імені підписувача в запиті CSR Kubernetes, ця функція дозволяє Istio інтегруватися з власними центрами сертифікації через API інтерфейс Kubernetes CSR. Це вимагає, щоб власний CA реалізував контролер Kubernetes для спостереження за ресурсами `CertificateSigningRequest` і обробки їх.

* Покращена багатокористувацька підтримка — Вказавши різних підписувачів сертифікатів для різних робочих навантажень, сертифікати для робочих навантажень різних користувачів можуть бути підписані різними центрами сертифікації.
