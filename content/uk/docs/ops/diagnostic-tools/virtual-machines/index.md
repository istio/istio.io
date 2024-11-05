---
title: Налагодження віртуальних машин
description: Описує інструменти та техніки для діагностики проблем з віртуальними машинами.
weight: 80
keywords: [debug,virtual-machines,envoy]
owner: istio/wg-environments-maintainers
test: n/a
---

Ця сторінка описує, як усувати проблеми з Istio, розгорнутим на віртуальних машинах. Перед тим як читати це, слід виконати кроки, зазначені у [Встановлення віртуальних машин](/docs/setup/install/virtual-machine/). Крім того, [Архітектура віртуальних машин](/docs/ops/deployment/vm-architecture/) може допомогти зрозуміти, як компоненти взаємодіють.

Усунення проблем з установкою Istio на віртуальних машинах схоже на усунення проблем з проксі, що працюють всередині Kubernetes, але є кілька ключових відмінностей, про які слід знати.

Хоча багато з тих же даних доступні на обох платформах, доступ до цієї інформації відрізняється.

## Моніторинг справності {#monitoring-health}

Sidecar Istio зазвичай запускається як одиниця `systemd`. Щоб переконатися, що він працює належним чином, ви можете перевірити його статус:

{{< text bash >}}
$ systemctl status istio
{{< /text >}}

Крім того, справність sidecar можна перевірити програмно на його точці доступу справності:

{{< text bash >}}
$ curl localhost:15021/healthz/ready -I
{{< /text >}}

## Логи {#logs}

Логи для проксі Istio можна знайти в кількох місцях.

Щоб отримати доступ до логів `systemd`, які містять деталі про ініціалізацію проксі:

{{< text bash >}}
$ journalctl -f -u istio -n 1000
{{< /text >}}

Проксі буде перенаправляти `stderr` і `stdout` до `/var/log/istio/istio.err.log` і `/var/log/istio/istio.log` відповідно. Щоб переглянути їх у форматі, схожому на `kubectl`:

{{< text bash >}}
$ tail /var/log/istio/istio.err.log /var/log/istio/istio.log -Fq -n 100
{{< /text >}}

Рівні логування можна змінити, редагуючи файл конфігурації `cluster.env`. Переконайтеся, що перезапустили `istio`, якщо він уже працює:

{{< text bash >}}
$ echo "ISTIO_AGENT_FLAGS=\"--log_output_level=dns:debug --proxyLogLevel=debug\"" >> /var/lib/istio/envoy/cluster.env
$ systemctl restart istio
{{< /text >}}

## Iptables {#iptables}

Щоб переконатися, що правила `iptables` були успішно застосовані:

{{< text bash >}}
$ sudo iptables-save
...
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
{{< /text >}}

## Istioctl {#istioctl}

Більшість команд `istioctl` працюватимуть належним чином з віртуальними машинами. Наприклад, `istioctl proxy-status` можна використовувати для перегляду всіх підключених проксі:

{{< text bash >}}
$ istioctl proxy-status
NAME           CDS        LDS        EDS        RDS      ISTIOD                    VERSION
vm-1.default   SYNCED     SYNCED     SYNCED     SYNCED   istiod-789ffff8-f2fkt     {{< istio_full_version >}}
{{< /text >}}

Однак `istioctl proxy-config` покладається на функціональність Kubernetes для підключення до проксі, що не буде працювати для віртуальних машин. Натомість можна передати файл, що містить дамп конфігурації з Envoy. Наприклад:

{{< text bash >}}
$ curl -s localhost:15000/config_dump | istioctl proxy-config clusters --file -
SERVICE FQDN                            PORT      SUBSET  DIRECTION     TYPE
istiod.istio-system.svc.cluster.local   443       -       outbound      EDS
istiod.istio-system.svc.cluster.local   15010     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15012     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15014     -       outbound      EDS
{{< /text >}}

## Автоматична реєстрація {#automatic-registration}

Коли віртуальна машина підключається до Istiod, автоматично створюється `WorkloadEntry`. Це дозволяє віртуальній машині стати частиною `Service`, подібно до `Endpoint` в Kubernetes.

Щоб перевірити, що вони створені правильно:

{{< text bash >}}
$ kubectl get workloadentries
NAME             AGE   ADDRESS
vm-10.128.0.50   14m   10.128.0.50
{{< /text >}}

## Сертифікати {#certificates}

Віртуальні машини обробляють сертифікати інакше, ніж Podʼи Kubernetes, які використовують токен службового облікового запису, наданий Kubernetes для автентифікації та оновлення сертифікатів mTLS. Натомість використовуються наявні облікові дані mTLS для автентифікації з органом сертифікації та оновлення сертифікатів.

Статус цих сертифікатів можна переглядати так само як і в Kubernetes:

{{< text bash >}}
$ curl -s localhost:15000/config_dump | ./istioctl proxy-config secret --file -
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           251932493344649542420616421203546836446     2021-01-29T18:07:21Z     2021-01-28T18:07:21Z
ROOTCA            CA             ACTIVE     true           81663936513052336343895977765039160718      2031-01-26T17:54:44Z     2021-01-28T17:54:44Z
{{< /text >}}

Крім того, ці сертифікати зберігаються на диску, щоб забезпечити збереження стану при простої або перезапусках.

{{< text bash >}}
$ ls /etc/certs
cert-chain.pem  key.pem  root-cert.pem
{{< /text >}}
