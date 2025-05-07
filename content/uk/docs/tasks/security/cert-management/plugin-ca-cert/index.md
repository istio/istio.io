---
title: Підключення сертифікатів ЦС
description: Демонструє, як системні адміністратори можуть налаштувати центр сертифікації Istio з кореневим сертифікатом, сертифікатом підпису та ключем.
weight: 80
keywords: [security,certificates]
aliases:
    - /uk/docs/tasks/security/plugin-ca-cert/
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як адміністратори можуть налаштувати центр сертифікації (ЦС, certificate authority — CA) Istio з кореневим сертифікатом, сертифікат підпису та ключ.

Стандартно центр сертифікації Istio генерує самопідписний кореневий сертифікат і ключ та використовує їх для підпису сертифікатів робочого навантаження. Щоб захистити кореневий ключ CA, слід використовувати кореневий центр сертифікації, який працює на безпечній машині офлайн, і використовувати кореневий CA для видачі проміжних сертифікатів центрам сертифікації Istio, які працюють у кожному кластері. Центр сертифікації Istio може підписувати сертифікати робочого навантаження за допомогою вказаного адміністратором сертифіката та ключа, а також розповсюджувати вказаний адміністратором кореневий сертифікат до робочих навантажень як кореневий довірчий сертифікат.

Наступна схема демонструє рекомендовану ієрархію CA у мережі, що містить два кластери.

{{< image width="50%"
    link="ca-hierarchy.svg"
    caption="Ієрархія CA"
    >}}

Це завдання демонструє, як згенерувати та підключити сертифікати та ключ для центру сертифікації Istio. Ці кроки можна повторити для забезпечення сертифікатами та ключами сертифікаційні центри Istio, що працюють у кожному кластері.

## Підключення сертифікатів і ключа до кластера {#plug-in-certificates-and-key-into-the-cluster}

{{< warning >}}
Наступні інструкції призначені лише для демонстраційних цілей. Для налаштування кластера для промислового використання настійно рекомендується використовувати CA промислового класу, такий як [Hashicorp Vault](https://www.hashicorp.com/products/vault). Доброю практикою є управління кореневим центром сертифікації на офлайн-машині з високим рівнем захисту.
{{< /warning >}}

{{< warning >}}
Підтримка підписів SHA-1 [вимкнена стандартно у Go 1.18](https://github.com/golang/go/issues/41682). Якщо ви генеруєте сертифікат на macOS, переконайтеся, що ви використовуєте OpenSSL, як описано у [GitHub issue 38049](https://github.com/istio/istio/issues/38049).
{{< /warning >}}

1.  У кореневій теці пакета встановлення Istio створіть теку для зберігання сертифікатів та ключів:

    {{< text bash >}}
    $ mkdir -p certs
    $ pushd certs
    {{< /text >}}

2.  Згенеруйте кореневий сертифікат і ключ:

    {{< text bash >}}
    $ make -f ../tools/certs/Makefile.selfsigned.mk root-ca
    {{< /text >}}

    Це призведе до створення наступних файлів:

    * `root-cert.pem`: згенерований кореневий сертифікат
    * `root-key.pem`: згенерований кореневий ключ
    * `root-ca.conf`: конфігурація для `openssl` для генерації кореневого сертифіката
    * `root-cert.csr`: згенерований CSR для кореневого сертифіката

3.  Для кожного кластера створіть проміжний сертифікат і ключ для Istio CA. Нижче наведено приклад для `cluster1`:

    {{< text bash >}}
    $ make -f ../tools/certs/Makefile.selfsigned.mk cluster1-cacerts
    {{< /text >}}

    Це призведе до створення наступних файлів у теці з назвою `cluster1`:

    * `ca-cert.pem`: згенеровані проміжні сертифікати
    * `ca-key.pem`: згенерований проміжний ключ
    * `cert-chain.pem`: згенерований ланцюжок сертифікатів, який використовується istiod
    * `root-cert.pem`: кореневий сертифікат

    Ви можете замінити `cluster1` на рядок за вашим вибором. Наприклад, з аргументом `cluster2-cacerts`, ви можете створити сертифікати та ключ у теці з назвою `cluster2`.

    Якщо ви виконуєте ці дії на офлайн-машині, скопіюйте згенеровану теку на машину з доступом до кластерів.

4.  У кожному кластері створіть secret `cacerts` з усіма вхідними файлами `ca-cert.pem`, `ca-key.pem`, `root-cert.pem` і `cert-chain.pem`. Наприклад, для `cluster1`:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
          --from-file=cluster1/ca-cert.pem \
          --from-file=cluster1/ca-key.pem \
          --from-file=cluster1/root-cert.pem \
          --from-file=cluster1/cert-chain.pem
    {{< /text >}}

5.  Повернутися до теки верхнього рівня встановлення Istio:

    {{< text bash >}}
    $ popd
    {{< /text >}}

## Розгортання Istio {#deploy-istio}

1.  Розгорніть Istio за допомогою профілю `demo`.

    Центр сертифікації Istio зчитає сертифікати та ключ з файлів secret-mount.

    {{< text bash >}}
    $ istioctl install --set profile=demo
    {{< /text >}}

## Розгортання демонстраційних сервісів {#deploying-example-services}

1. Розгорніть демонстраційні сервіси `httpbin` та  `curl`.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/curl/curl.yaml) -n foo
    {{< /text >}}

2. Розгорніть політику для робочих навантажень у просторі імен `foo`, щоб приймати лише взаємний TLS-трафік.

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: PeerAuthentication
    metadata:
      name: "default"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

## Перевірка сертифікатів {#verifying-the-certificates}

У цьому розділі ми перевіримо, що сертифікати робочого навантаження підписані тими сертифікатами, які були підключені до CA. Для цього необхідно, щоб на вашій машині було встановлено `openssl`.

1.  Почекайте 20 секунд, щоб політика mTLS набула чинності, перш ніж отримати ланцюжок сертифікатів для `httpbin`. Оскільки сертифікат CA, що використовується в цьому прикладі, є самопідписним, помилка `verify error:num=19:self signed certificate in certificate chain`, що повертається командою openssl, є очікуваною.

    {{< text bash >}}
    $ sleep 20; kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt
    {{< /text >}}

1.  Проаналізуйте сертифікати в ланцюжку сертифікатів.

    {{< text bash >}}
    $ sed -n '/-----BEGIN CERTIFICATE-----/{:start /-----END CERTIFICATE-----/!{N;b start};/.*/p}' httpbin-proxy-cert.txt > certs.pem
    $ awk 'BEGIN {counter=0;} /BEGIN CERT/{counter++} { print > "proxy-cert-" counter ".pem"}' < certs.pem
    {{< /text >}}

1.  Переконайтеся, що кореневий сертифікат збігається з тим, який вказав адміністратор:

    {{< text bash >}}
    $ openssl x509 -in certs/cluster1/root-cert.pem -text -noout > /tmp/root-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-3.pem -text -noout > /tmp/pod-root-cert.crt.txt
    $ diff -s /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
    Files /tmp/root-cert.crt.txt and /tmp/pod-root-cert.crt.txt are identical
    {{< /text >}}

1.  Переконайтеся, що сертифікат ЦС збігається з сертифікатом, вказаним адміністратором:

    {{< text bash >}}
    $ openssl x509 -in certs/cluster1/ca-cert.pem -text -noout > /tmp/ca-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-2.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
    $ diff -s /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
    Files /tmp/ca-cert.crt.txt and /tmp/pod-cert-chain-ca.crt.txt are identical
    {{< /text >}}

1.  Перевірте ланцюжок сертифікатів від кореневого сертифіката до сертифіката робочого навантаження:

    {{< text bash >}}
    $ openssl verify -CAfile <(cat certs/cluster1/ca-cert.pem certs/cluster1/root-cert.pem) ./proxy-cert-1.pem
    ./proxy-cert-1.pem: OK
    {{< /text >}}

## Очищення {#cleanup}

*   Видаліть сертифікати, ключі та проміжні файли з локального диска:

    {{< text bash >}}
    $ rm -rf certs
    {{< /text >}}

*   Видаліть secret `cacerts`:

    {{< text bash >}}
    $ kubectl delete secret cacerts -n istio-system
    {{< /text >}}

*   Видаліть політику автентифікації з простору імен `foo`:

    {{< text bash >}}
    $ kubectl delete peerauthentication -n foo default
    {{< /text >}}

*   Видаліть демонстраційні застосунки `curl` та `httpbin`:

    {{< text bash >}}
    $ kubectl delete -f samples/curl/curl.yaml -n foo
    $ kubectl delete -f samples/httpbin/httpbin.yaml -n foo
    {{< /text >}}

*   Видаліть Istio з кластера:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

*   Видалити простір імен `foo` та `istio-system` з кластера:

    {{< text bash >}}
    $ kubectl delete ns foo istio-system
    {{< /text >}}
