---
title: Lightstep
description: Як налаштувати проксі для надсилання трейсів до Lightstep.
weight: 70
keywords: [telemetry,tracing,lightstep]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/lightstep/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

{{< boilerplate telemetry-tracing-tips >}}

Це завдання показує, як налаштувати Istio для збору відрізків (span) трейсингу та надсилання їх до [Lightstep](https://lightstep.com). Lightstep дозволяє аналізувати 100% недискретизованих даних транзакцій з великомасштабного промислового програмного забезпечення для створення значущих розподілених трейсів і метрик, які допомагають пояснити поведінку продуктивності і прискорити аналіз першопричин. В кінці цього завдання Istio надсилатиме відрізки трейсів з проксі до пулу Lightstep Satellite, роблячи їх доступними у вебінтерфейсі. Стандартно перехоплюються всі HTTP-запити (щоб побачити наскрізні трейси, ваш код повинен пересилати OT-заголовки, навіть якщо він не приєднується до трейсів).

Якщо ви хочете збирати відрізки трейсів безпосередньо з Istio (і не додавати специфічні інструменти безпосередньо до вашого коду), вам не потрібно налаштовувати жодні трейсери, якщо ваші сервіси передають [HTTP заголовки, згенеровані трейсами](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/headers#config-http-conn-man-headers-x-ot-span-context).

Це завдання використовує [Bookinfo](/docs/examples/bookinfo/) як демонстраційний застосунок.

## Перед початком {#before-you-begin}

1. Переконайтеся, що у вас є обліковий запис Lightstep. [Зареєструйтесь](https://go.lightstep.com/trial) на безкоштовний пробний період Lightstep.

1. Якщо ви використовуєте [локальні Satellites](https://docs.lightstep.com/docs/learn-about-satellites#on-premise-satellites), переконайтеся, що у вас є налаштований пул супутників з TLS сертифікатами та захищеним GRPC портом. Дивіться [Встановлення та налаштування супутників](https://docs.lightstep.com/docs/install-and-configure-satellites) для отримання деталей про налаштування супутників.

    Для [публічних Satellites Lightstep](https://docs.lightstep.com/docs/learn-about-satellites#public-satellites) або [супутників для розробників](https://docs.lightstep.com/docs/learn-about-satellites#developer-satellites) ваші супутники вже налаштовані. Однак вам потрібно завантажити [цей сертифікат](https://docs.lightstep.com/docs/instrument-with-istio-as-your-service-mesh#cacertpem-file) у локальну теку.

1. Переконайтеся, що у вас є [токен доступу Lightstep](https://docs.lightstep.com/docs/create-and-manage-access-tokens). Токени доступу дозволяють вашій програмі спілкуватися з вашим проєктом Lightstep.

## Розгортання Istio {#deploy-istio}

Як ви розгортаєте Istio, залежить від типу супутника, який ви використовуєте.

### Розгортання Istio з локальними супутниками {#deploy-istio-with-on-premise-satellites}

Ці інструкції не припускають використання TLS. Якщо ви використовуєте TLS для вашого пулу супутників, дотримуйтеся конфігурації для [Публічного пулу супутників](#deploy-istio-with-public-or-developer-mode-satellites), але використовуйте свій сертифікат та адресу вашого пулу (`host:port`).

1. Вам потрібно розгорнути Istio з адресою вашого супутника у форматі `<Host>:<Port>`, наприклад `lightstep-satellite.lightstep:9292`. Ви знайдете це у вашому [файлі конфігурації](https://docs.lightstep.com/docs/satellite-configuration-parameters#ports).

1. Розгорніть Istio з наступними параметрами конфігурації:
    - `global.proxy.tracer="lightstep"`
    - `meshConfig.defaultConfig.tracing.sampling=100`
    - `meshConfig.defaultConfig.tracing.lightstep.address="<satellite-address>"`
    - `meshConfig.defaultConfig.tracing.lightstep.accessToken="<access-token>"`

    Ви можете встановити ці параметри за допомогою синтаксису `--set key=value` під час виконання команди встановлення. Наприклад:

    {{< text bash >}}
    $ istioctl install \
        --set global.proxy.tracer="lightstep" \
        --set meshConfig.defaultConfig.tracing.sampling=100 \
        --set meshConfig.defaultConfig.tracing.lightstep.address="<satellite-address>" \
        --set meshConfig.defaultConfig.tracing.lightstep.accessToken="<access-token>" \
    {{< /text >}}

### Розгортання Istio з публічними або супутниками для розробників {#deploy-istio-with-public-or-developer-mode-satellites}

Слідуйте цим крокам, якщо ви використовуєте публічні або супутники для розробників, або якщо ви використовуєте локальні супутники з сертифікатом TLS.

1. Зберігайте сертифікат авторитету вашого пулу супутників як секрет у просторі імен `default` та `istio-system`, останній для використання шлюзами Istio. Завантажте і використовуйте [цей сертифікат](https://docs.lightstep.com/docs/instrument-with-istio-as-your-service-mesh#cacertpem-file). Якщо ви розгортаєте застосунок Bookinfo в іншому просторі імен, створіть секрет у цьому просторі імен.

    {{< text bash >}}
    $ CACERT=$(cat Cert_Auth.crt | base64) # Cert_Auth.crt містить необхідний CACert
    $ NAMESPACE=default
    {{< /text >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Secret
      metadata:
        name: lightstep.cacert
        namespace: $NAMESPACE
        labels:
          app: lightstep
      type: Opaque
      data:
        cacert.pem: $CACERT
    EOF
    {{< /text >}}

1. Розгорніть Istio з наступними параметрами конфігурації:

    {{< text yaml >}}
    global:
      proxy:
        tracer: "lightstep"
    meshConfig:
      defaultConfig:
        tracing:
          lightstep:
            address: "ingest.lightstep.com:443"
            accessToken: "<access-token>"
          sampling: 100
          tlsSettings:
            mode: "SIMPLE"
            # Вказівка сертифіката CA тут монтує том `lightstep.cacert`
            # до всіх sidecar за замовчуванням.
            caCertificates="/etc/lightstep/cacert.pem"
    components:
      ingressGateways:
      # Том секрету `lightstep.cacert` потрібно змонтувати до шлюзів через k8s overlay.
      - name: istio-ingressgateway
        enabled: true
        k8s:
          overlays:
          - kind: Deployment
            name: istio-ingressgateway
            patches:
            - path: spec.template.spec.containers[0].volumeMounts[-1]
              value: |
                name: lightstep-certs
                mountPath: /etc/lightstep
                readOnly: true
            - path: spec.template.spec.volumes[-1]
              value: |
                name: lightstep-certs
                secret:
                  secretName: lightstep.cacert
                  optional: true
    {{< /text >}}

## Встановлення та запуск Bookinfo {#install-and-run-the-bookinfo-app}

1. Слідуйте [інструкціям для розгортання демонстраційного застосунку Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

1. Слідуйте [інструкціям для створення шлюзу для застосунку Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

1. Щоб перевірити успішність попереднього кроку, підтверджуйте, що ви встановили змінну середовища `GATEWAY_URL` у вашій оболонці.

1. Надішліть трафік до демонстраційного застосунку.

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

## Візуалізація даних трейсингу {#visualize-trace-data}

1. Завантажте [вебінтерфейс Lightstep](https://app.lightstep.com/). Ви побачите три сервіси Bookinfo в Service Directory.

    {{< image link="./istio-services.png" caption="Сервіси Bookfinder у Service Directory" >}}

1. Перейдіть до Explorer.

    {{< image link="./istio-explorer.png" caption="Explorer" >}}

1. Знайдіть рядок запиту зверху. Рядок запиту дозволяє вам інтерактивно фільтрувати результати за **Сервісом**, **Операцією** та **Значеннями теґів**.

1. Виберіть `productpage.default` зі списку **Сервіс**.

1. Натисніть **Run**. Ви побачите щось подібне до:

    {{< image link="./istio-tracing-list-lightstep.png" caption="Explorer" >}}

1. Натисніть на перший рядок у таблиці прикладів трейсів під гістограмою затримки, щоб переглянути деталі відповідно до вашого оновлення `/productpage`. Сторінка потім виглядає так:

    {{< image link="./istio-tracing-details-lightstep.png" caption="Детальний перегляд трейсів" >}}

Скріншот показує, що трейс складається з набору відрізків. Кожен відрізок відповідає за один з сервісів Bookinfo, викликаних під час виконання запиту `/productpage`.

Два відрізки в трейсингу представляють кожен RPC. Наприклад, виклик з `productpage` до `reviews` починається з відрізку, позначеного операцією `reviews.default.svc.cluster.local:9080/*` і сервісом `productpage.default: proxy client`. Цей сервіс представляє клієнтський відрізок виклику. Скріншот показує, що виклик зайняв 15.30 мс. Другий відрізок позначений операцією `reviews.default.svc.cluster.local:9080/*` і сервісом `reviews.default: proxy server`. Другий відрізок є дитиною першого відрізку і представляє серверний відрізок виклику. Скріншот показує, що виклик зайняв 14.60 мс.

## Зразки трейсів {#trace-sampling}

Istio захоплює трейсинги з налаштовуваним відсотком зразків трейсів. Щоб дізнатися, як змінити відсоток зразків трейсів, відвідайте [секцію зразків трейсів розподіленого трейсингу](/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/#customizing-trace-sampling).

При використанні Lightstep, ми не рекомендуємо зменшувати відсоток зразків трейсів нижче 100%. Щоб впоратися з високим трафіком у мережі, розгляньте можливість масштабування розміру вашого пулу супутників.

## Очищення {#cleanup}

Якщо ви не плануєте подальші завдання, видаліть демонстраційний застосунок Bookinfo і будь-які секрети Lightstep з вашого кластера.

1. Щоб видалити застосунок Bookinfo, дотримуйтеся [інструкцій з очищення Bookinfo](/docs/examples/bookinfo/#cleanup).

1. Видаліть секрет, створений для Lightstep:

{{< text bash >}}
$ kubectl delete secret lightstep.cacert
{{< /text >}}
