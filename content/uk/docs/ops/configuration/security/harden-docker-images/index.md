---
title: Зміцнення образів контейнерів Docker
description: Використовуйте зміцнені образи контейнерів, щоб зменшити поверхню атаки Istio.
weight: 80
aliases:
  - /uk/help/ops/security/harden-docker-images
  - /uk/docs/ops/security/harden-docker-images
owner: istio/wg-security-maintainers
test: n/a
status: Beta
---

Стандартні [образи Istio](https://hub.docker.com/r/istio/base) базуються на `ubuntu` з доданими додатковими інструментами. Альтернативні образи на основі [distroless images](https://github.com/GoogleContainerTools/distroless) також доступні.

Ці образи видаляють всі непотрібні виконувані файли та бібліотеки, що пропонує такі переваги:

- Зменшено поверхню атаки, оскільки включено найменший можливий набір вразливостей.
- Образи менші, що дозволяє швидший запуск.

Дивіться також розділ [Why should I use distroless images?](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images) у офіційному README distroless.

## Встановлення distroless образів {#install-distroless-images}

Слідуйте [Інструкціям з установки](/docs/setup/install/istioctl/) для налаштування Istio. Додайте опцію `variant`, щоб використовувати *distroless images*.

{{< text bash >}}
$ istioctl install --set values.global.variant=distroless
{{< /text >}}

Якщо вас цікавлять тільки distroless образи для проксі образів для інʼєкцій, ви також можете використовувати поле `image.imageType` у [Proxy Config](/docs/reference/config/networking/proxy-config/#ProxyImage). Зазначте, що вищезгаданий прапорець `variant` автоматично налаштує це за вас.

## Налагодження {#debugging}

Distroless образи не містять жодних інструментів для налагодження (включаючи оболонку!). Хоча це чудово для безпеки, це обмежує можливість виконання ad-hoc налагодження за допомогою `kubectl exec` у контейнері проксі.

На щастя, [Ефемерні контейнери](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/) можуть допомогти в цьому. `kubectl debug` може прикріпити тимчасовий контейнер до podʼа. Використовуючи образ з додатковими інструментами, ми можемо налагоджувати як раніше:

{{< text shell >}}
$ kubectl debug --image istio/base --target istio-proxy -it app-65c6749c9d-t549t
Defaulting debug container name to debugger-cdftc.
If you don't see a command prompt, try pressing enter.
root@app-65c6749c9d-t549t:/# curl example.com
{{< /text >}}

Це розгортає новий тимчасовий контейнер, використовуючи `istio/base`. Це той самий базовий образ, що використовується в не-distroless образах Istio, і містить різноманітні інструменти, корисні для налагодження Istio. Однак будь-який образ буде працювати. Контейнер також приєднано до простору імен процесу sidecar проксі (`--target istio-proxy`) та мережевого простору імен podʼа.
