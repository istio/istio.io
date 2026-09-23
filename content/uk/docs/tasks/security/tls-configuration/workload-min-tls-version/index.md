---
title: Конфігурація мінімальної версії TLS для робочих навантажень Istio
description: Показує, як налаштувати мінімальну версію TLS для робочих навантажень Istio.
weight: 90
keywords: [security,TLS]
aliases:
- /docs/tasks/security/workload-min-tls-version/
owner: istio/wg-security-maintainers
test: yes
---

Ця задача показує, як налаштувати мінімальну версію TLS для робочих навантажень Istio.
Максимальна версія TLS для робочих навантажень Istio — 1.3.

## Конфігурація мінімальної версії TLS для робочих навантажень Istio {#configuration-of-minimum-tls-version-for-istio-workloads}

* Встановіть Istio через `istioctl` з налаштованою мінімальною версією TLS. Власний ресурс `IstioOperator`, що використовується для конфігурації Istio в команді `istioctl install`, містить поле для мінімальної версії TLS для робочих навантажень Istio. Поле `minProtocolVersion` визначає мінімальну версію TLS для TLS-зʼєднань між робочими навантаженнями Istio. У наступному прикладі, мінімальна версія TLS для робочих навантажень Istio налаштована на 1.3.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        meshMTLS:
          minProtocolVersion: TLSV1_3
    EOF
    $ istioctl install -f ./istio.yaml
    {{< /text >}}

## Перевірка конфігурації TLS робочих навантажень Istio {#check-the-tls-configuration-of-istio-workloads}

Після конфігурації мінімальної версії TLS для робочих навантажень Istio, ви можете перевірити, що мінімальна версія TLS налаштована і працює як очікується.

* Розгорніть два робочих навантаження: `httpbin` та `curl`. Розгорніть їх в одному просторі імен, наприклад, `foo`. Обидва робочих навантаження працюють з проксі Envoy попереду.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    {{< /text >}}

* Перевірте, що `curl` успішно спілкується з `httpbin`, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Якщо ви не бачите очікуваного результату, повторіть спробу через кілька секунд. Кешування і затримка поширення можуть спричинити деяку затримку.
{{< /warning >}}

У цьому прикладі мінімальна версія TLS була налаштована на 1.3. Щоб перевірити, що TLS 1.3 дозволено, виконайте наступну команду:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_3 -connect httpbin.foo:8000 | grep "TLSv1.3"
{{< /text >}}

Вивід повинен містити:

{{< text plain >}}
TLSv1.3
{{< /text >}}

Щоб перевірити, що TLS 1.2 не дозволено, виконайте наступну команду:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_2 -connect httpbin.foo:8000 | grep "Cipher is (NONE)"
{{< /text >}}

Вивід повинен містити:

{{< text plain >}}
Cipher is (NONE)
{{< /text >}}

## Очищення {#cleanup}

Видаліть застосунки `curl` і `httpbin` з простору імен `foo`:

{{< text bash >}}
$ kubectl delete -f samples/httpbin/httpbin.yaml -n foo
$ kubectl delete -f samples/curl/curl.yaml -n foo
{{< /text >}}

Видаліть Istio з кластера:

{{< text bash >}}
$ istioctl uninstall --purge -y
{{< /text >}}

Щоб видалити простори імен `foo` та `istio-system`:

{{< text bash >}}
$ kubectl delete ns foo istio-system
{{< /text >}}
