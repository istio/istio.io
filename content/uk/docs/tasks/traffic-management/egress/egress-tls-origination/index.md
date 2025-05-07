---
title: Створення TLS для вихідного трафіку
description: Описує, як налаштувати Istio на створення TLS для трафіку до зовнішніх сервісів.
keywords: [traffic-management,egress]
weight: 20
owner: istio/wg-networking-maintainers
test: yes
aliases:
  - /uk/docs/examples/advanced-gateways/egress-tls-origination/
---

Завдання [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control) демонструє, як HTTP та HTTPS сервіси, що знаходяться поза межами сервісної мережі (service mesh), можуть бути доступні з застосунків всередині mesh. Як описано в цьому завданні, [`ServiceEntry`](/docs/reference/config/networking/service-entry/) використовується для налаштування доступу до зовнішніх сервісів у контрольований спосіб через Istio. У цьому прикладі показано, як налаштувати Istio для виконання {{< gloss "Створення TLS" >}}створення TLS{{< /gloss >}} для трафіку до зовнішнього сервісу. Istio відкриє HTTPS-зʼєднання із зовнішнім сервісом, тоді як оригінальний трафік буде HTTP.

## Використання {#use-case}

Розглянемо приклад старого застосунку, який здійснює HTTP-запити до зовнішніх сайтів. Припустимо, організація, що керує застосунком, отримує нову вимогу, яка передбачає шифрування всього зовнішнього трафіку. З Istio цю вимогу можна реалізувати лише за допомогою конфігурації, без необхідності змінювати код застосунку. Застосунок може надсилати незашифровані HTTP-запити, а Istio зашифрує їх для нього.

Ще однією перевагою надсилання незашифрованих HTTP-запитів від джерела та дозволу Istio виконувати оновлення до TLS є те, що Istio може створювати кращу телеметрію та надавати більше контролю за маршрутизацією для запитів, які не зашифровані.

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/).

* Запустіть демонстраційний застосунок [curl]({{< github_tree >}}/samples/curl), який буде використовуватися як тестове джерело для зовнішніх викликів.

    Якщо у вас увімкнено [автоматичну інʼєкцію sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), виконайте наступну команду, розгорніть застосунок `curl`:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    В іншому випадку вам потрібно вручну виконати інʼєкцію sidecar перед розгортанням застосунку `curl`:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    Зверніть увагу, що будь-який pod, з якого ви можете виконати `exec` та `curl`, підійде для подальших процедур.

* Створіть змінну shell для збереження імені podʼа джерела для надсилання запитів до зовнішніх сервісів. Якщо ви використовували [curl]({{< github_tree >}}/samples/curl), виконайте:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Налаштування доступу до зовнішнього сервісу {#configuring-access-to-an-external-service}

Спочатку налаштуйте доступ до зовнішнього сервісу, `edition.cnn.com`, використовуючи ту саму техніку, що й у завданні [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control). Цього разу, однак, використовуйте один `ServiceEntry` для увімкнення як HTTP, так і HTTPS доступу до сервісу.

1.  Створіть `ServiceEntry`, щоб увімкнути доступ до `edition.cnn.com`:

    {{< text syntax=bash snip_id=apply_simple >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Зробіть запит до зовнішнього HTTP-сервісу:

    {{< text syntax=bash snip_id=curl_simple >}}
    $ kubectl exec "${SOURCE_POD}" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    ...
    {{< /text >}}

    Вихідні дані мають бути схожими на наведені вище (деякі деталі замінено на багатокрапки).

Зверніть увагу на прапорець `-L` у _curl_, який вказує _curl_ слідувати за перенаправленнями. У цьому випадку сервер повернув відповідь про перенаправлення ([301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2)) на HTTP запит до `http://edition.cnn.com/politics`. Відповідь про перенаправлення вказує клієнту надіслати додатковий запит, цього разу з використанням HTTPS, до `https://edition.cnn.com/politics`. Для другого запиту сервер повернув запитуваний контент і статус-код _200 OK_.

Хоча команда _curl_ обробила перенаправлення прозоро, є дві проблеми. Перша проблема — це надмірний запит, який подвоює затримку при отриманні контенту з `http://edition.cnn.com/politics`. Друга проблема полягає в тому, що шлях URL, _politics_ у цьому випадку, надсилається у відкритому тексті. Якщо є зловмисник, який перехоплює комунікацію між вашим застосунком та `edition.cnn.com`, зловмисник знатиме, які конкретні теми з `edition.cnn.com` застосунок отримав. З міркувань конфіденційності ви можете захотіти запобігти такому розголошенню.

Обидві ці проблеми можна вирішити, налаштувавши Istio для виконання створення TLS (TLS origination).

## Створення TLS для вихідного трафіку {#tls-origination-for-egress-traffic}

1.  Перевизначте ваш `ServiceEntry` з попереднього розділу, щоб перенаправляти HTTP-запити на порт 443 і додайте `DestinationRule` для виконання створення TLS:

    {{< text syntax=bash snip_id=apply_origination >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
        targetPort: 443
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        portLevelSettings:
        - port:
            number: 80
          tls:
            mode: SIMPLE # ініціює HTTPS під час доступу до edition.cnn.com
    EOF
    {{< /text >}}

    Вищевказане `DestinationRule` виконає створення TLS для HTTP-запитів на порту 80, а `ServiceEntry` буде перенаправляти запити на порт 80 на цільовий порт 443.

2. Надішліть HTTP-запит на `http://edition.cnn.com/politics`, як у попередньому розділі:

    {{< text syntax=bash snip_id=curl_origination_http >}}
    $ kubectl exec "${SOURCE_POD}" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    Цього разу ви отримали відповідь _200 OK_ як першу і єдину відповідь. Istio виконав TLS origination для _curl_, тому оригінальний HTTP запит був перенаправлений до `edition.cnn.com` як HTTPS. Сервер повернув контент без потреби в перенаправленні. Ви усунули подвійний обмін між клієнтом і сервером, а запит залишив мережу у зашифрованому вигляді, не розголошуючи, що ваш застосунок отримав розділ _politics_ з `edition.cnn.com`.

    Зверніть увагу, що ви використали ту ж команду, що і в попередньому розділі. Для застосунків, які отримують доступ до зовнішніх служб програмно, код змінювати не потрібно. Ви отримуєте переваги TLS origination, налаштувавши Istio, без потреби змінювати жодного рядка коду.

3.  Зверніть увагу, що застосунки, які використовували HTTPS для доступу до зовнішнього сервісу, продовжують працювати як і раніше:

    {{< text syntax=bash snip_id=curl_origination_https >}}
    $ kubectl exec "${SOURCE_POD}" -c curl -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/2 200
    ...
    {{< /text >}}

## Додаткові міркування з безпеки {#additional-security-considerations}

Оскільки трафік між застосунком та sidecar проксі на локальному хості все ще не зашифрований, зловмисник, який зможе проникнути на вузол вашого застосунку, зможе побачити нешифрований звʼязок в локальній мережі вузла. У деяких середовищах суворі вимоги до безпеки можуть вимагати, щоб весь трафік був зашифрований, навіть в локальній мережі вузлів. З такими суворими вимогами застосунки повинні використовувати лише HTTPS (TLS). TLS origination, описаний у цьому прикладі, не буде достатнім.

Також слід зазначити, що навіть з HTTPS, ініційованим застосунком, зловмисник може дізнатися, що запити до `edition.cnn.com` надсилаються, перевіряючи [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication). Поле _SNI_ надсилається нешифрованим під час рукостискання TLS. Використання HTTPS запобігає зловмисникам знати конкретні теми та статті, але не заважає зловмисникам дізнатися, що був виконаний доступ до `edition.cnn.com`.

### Видалення конфігурації TLS origination {#cleanup-the-tls-origination-configuration}

Видаліть створені вами елементи конфігурації Istio:

{{< text bash >}}
$ kubectl delete serviceentry edition-cnn-com
$ kubectl delete destinationrule edition-cnn-com
{{< /text >}}

## Взаємний TLS для вихідного трафіку {#mutual-tls-origination-for-egress-traffic}

У цьому розділі описується, як налаштувати sidecar для виконання TLS-автентифікації для зовнішнього сервісу, цього разу використовуючи сервіс, що потребує взаємної автентифікації TLS. Цей приклад значно складніший, оскільки він вимагає наступної конфігурації:

1. Створення сертифікатів клієнта та сервера
1. Розгортання зовнішнього сервісу, який підтримує протокол взаємної автентифікації TLS
1. Налаштування клієнта (curl pod) на використання облікових даних, створених на Кроці 1

Коли ця конфігурація буде завершена, ви зможете налаштувати зовнішній трафік так, щоб він проходив через sidecar, який виконає TLS-автентифікацію.

### Створення сертифікатів і ключів клієнта та сервера {#generate-client-and-server-certificates-and-keys}

Для цього завдання ви можете використовувати будь-який зручний для вас інструмент для створення сертифікатів і ключів. Команди нижче використовують [openssl](https://man.openbsd.org/openssl.1).

1.  Створіть кореневий сертифікат та приватний ключ для підписання сертифіката для ваших сервісів:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  Створіть сертифікат і приватний ключ для `my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

    За бажанням ви можете додати `SubjectAltNames` до сертифіката, якщо хочете увімкнути перевірку SAN для місця призначення. Наприклад:

    {{< text syntax=bash snip_id=none >}}
    $ cat > san.conf <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    x509_extensions = v3_req
    prompt = no
    [req_distinguished_name]
    countryName = US
    [v3_req]
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    basicConstraints = critical, CA:FALSE
    subjectAltName = critical, @alt_names
    [alt_names]
    DNS = my-nginx.mesh-external.svc.cluster.local
    EOF
    $
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:4096 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization" -config san.conf
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt -extfile san.conf -extensions v3_req
    {{< /text >}}

1.  Згенеруйте клієнтський сертифікат і приватний ключ:

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### Розгортання сервера з взаємною автентифікацією TLS {#deploy-a-mutual-tls-server}

Щоб симулювати справжній зовнішній сервіс, який підтримує протокол взаємної автентифікації TLS, розгорніть сервер [NGINX](https://www.nginx.com) у вашому кластері Kubernetes, але запустіть його поза мережею сервісів Istio, тобто в просторі імен без увімкненого інжектора sidecar проксі Istio.

1.  Створіть простір імен для представлення сервісів поза мережею Istio, а саме `mesh-external`. Зверніть увагу, що sidecar проксі не буде автоматично додаватися в podʼах цього простору імен, оскільки автоматична інʼєкція sidecar не була [увімкнена](/docs/setup/additional-setup/sidecar-injection/#deploying-an-app) для цього простору.

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

2. Створіть Kubernetes [Secrets] (https://kubernetes.io/docs/concepts/configuration/secret/) для зберігання сертифікатів сервера та центру сертифікації.

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

3.  Створіть конфігураційний файл для сервера NGINX:

    {{< text bash >}}
    $ cat <<\EOF > ./nginx.conf
    events {
    }

    http {
      log_format main '$remote_addr - $remote_user [$time_local]  $status '
      '"$request" $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name my-nginx.mesh-external.svc.cluster.local;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
        ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

4.  Створіть Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) для зберігання конфігурації сервера NGINX:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

5.  Розгорніть сервер NGINX:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
      labels:
        run: my-nginx
      annotations:
        "networking.istio.io/exportTo": "." # simulate an external service by not exporting outside this namespace
    spec:
      ports:
      - port: 443
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
      namespace: mesh-external
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
        spec:
          containers:
          - name: my-nginx
            image: nginx
            ports:
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

### Налаштуйте клієнта (curl pod) {#configure-the-client-curl-pod}

1.  Створіть Kubernetes [Secrets] (https://kubernetes.io/docs/concepts/configuration/secret/) для зберігання сертифікатів клієнта:

    {{< text bash >}}
    $ kubectl create secret generic client-credential --from-file=tls.key=client.example.com.key \
      --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
    {{< /text >}}

    Секрет **має бути** створений у тому ж просторі імен, у якому розгорнуто клієнтський pod, у даному випадку `default`.

    {{< tip >}}
    {{< boilerplate crl-tip >}}
    {{< /tip >}}

1. Створіть необхідний `RBAC`, щоб переконатися, що секрет, створений на попередньому кроці, доступний клієнтському pod, який ' у цьому випадку — `curl`.

    {{< text bash >}}
    $ kubectl create role client-credential-role --resource=secret --verb=list
    $ kubectl create rolebinding client-credential-role-binding --role=client-credential-role --serviceaccount=default:curl
    {{< /text >}}

### Налаштування взаємного TLS для вихідного трафіку на sidecar {#configure-mutual-tls-origination-for-egress-traffic-at-sidecar}

1.  Додайте `ServiceEntry` для перенаправлення HTTP-запитів на порт 443 і додайте `DestinationRule` для виконання взаємного TLS origination:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: originate-mtls-for-nginx
    spec:
      hosts:
      - my-nginx.mesh-external.svc.cluster.local
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
        targetPort: 443
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: originate-mtls-for-nginx
    spec:
      workloadSelector:
        matchLabels:
          app: curl
      host: my-nginx.mesh-external.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 80
          tls:
            mode: MUTUAL
            credentialName: client-credential # це має збігатися з секретом, створеним раніше для зберігання клієнтських сертифікатів, і працює тільки тоді, коли DR має workloadSelector
            sni: my-nginx.mesh-external.svc.cluster.local
            # subjectAltNames: # можна ввімкнути, якщо сертифікат було згенеровано за допомогою SAN, як зазначено в попередньому розділі
            # - my-nginx.mesh-external.svc.cluster.local
    EOF
    {{< /text >}}

    Вищевказане правило `DestinationRule` виконає створення mTLS для HTTP-запитів на порт 80, а `ServiceEntry` буде перенаправляти запити на порт 80 на цільовий порт 443.

    {{< boilerplate auto-san-validation >}}

2.  Переконайтеся, що обліковий запис підʼєднано до sidecar та активовано.

    {{< text bash >}}
    $ istioctl proxy-config secret deploy/curl | grep client-credential
    kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:15:20Z     2023-06-05T12:15:20Z
    kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           10792363984292733914                       2024-06-04T12:15:19Z     2023-06-05T12:15:19Z
    {{< /text >}}

3.  Надішліть HTTP-запит до `http://my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

4.  Перевірте лог podʼа `curl` на наявність радка, що відповідає вашому запиту.

    {{< text bash >}}
    $ kubectl logs -l app=curl -c istio-proxy | grep 'my-nginx.mesh-external.svc.cluster.local'
    {{< /text >}}

    Ви повинні побачити рядок, схожий на наступний:

    {{< text plain>}}
    [2022-05-19T10:01:06.795Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 1 0 "-" "curl/7.83.1-DEV" "96e8d8a7-92ce-9939-aa47-9f5f530a69fb" "my-nginx.mesh-external.svc.cluster.local:443" "10.107.176.65:443"
    {{< /text >}}

### Видалення конфігурації взаємного TLS origination {#cleanup-the-mutual-tls-origination-configuration}

1.  Видаліть створені ресурси Kubernetes:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret client-credential
    $ kubectl delete rolebinding client-credential-role-binding
    $ kubectl delete role client-credential-role
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    $ kubectl delete serviceentry originate-mtls-for-nginx
    $ kubectl delete destinationrule originate-mtls-for-nginx
    {{< /text >}}

1.  Видаліть сертифікати та приватні ключі:

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

1.  Видаліть згенеровані конфігураційні файли, використані у цьому прикладі:

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}

## Очищення загальної конфігурації {#cleanup-common-configuration}

Видалити сервіс `curl` та розгортання:

{{< text bash >}}
$ kubectl delete service curl
$ kubectl delete deployment curl
{{< /text >}}
