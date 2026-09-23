---
title: Сумісність версій
description: Як налаштувати "сумісність версій", щоб відокремити зміни в поведінці від випусків.
weight: 36
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

З кожною новою версією Istio можуть зʼявлятися навмисні зміни в поведінці. Це можуть бути зміни для покращення безпеки, виправлення некоректної поведінки або інші покращення для користувачів Istio. Зазвичай такі зміни впливають лише на крайні випадки використання.

Хоча ці зміни є корисними в довгостроковій перспективі, кожна з них під час оновлення несе певний ризик. Раніше, при оновленні, користувачам потрібно було переглядати примітки до випусків, щоб дізнатися про зміни в поведінці та визначити, чи впливають вони на їхні налаштування; це може бути складним і помилковим процесом.

Сумісність версій дає користувачам додатковий варіант, дозволяючи відокремити версії випусків від змін в поведінці. Наприклад, ви можете встановити Istio {{< istio_version >}}, але налаштувати його так, щоб він поводився, як {{< istio_previous_version >}}.

## Використання сумісності версій {#using-compatibility-versions}

Щоб використовувати сумісність версій, просто встановіть поле `compatibilityVersion`.

{{< tabset category-name="install" >}}
{{< tab name="IstioOperator" category-value="iop" >}}

{{< text shell >}}
$ istioctl install --set values.compatibilityVersion={{< istio_previous_version >}}
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

{{< text shell >}}
$ helm install ... --set compatibilityVersion={{< istio_previous_version >}}
{{< /text >}}

{{< /tab >}}
{{< /tabset >}}

## Коли варто використовувати сумісність версій? {#when-should-i-use-compatibility-versions}

Сумісність версій слід використовувати лише тоді, коли існує несумісність між випусками, як тимчасовий захід. Ви повинні планувати перехід на нову поведінку, як тільки це стане можливим.

Сумісність версій для випуску буде вилучено і більше не підтримуватиметься, коли випуск, до якого вони відносяться, досягне кінця свого життєвого циклу. Зверніться до [стану підтримки поточного випуску Istio](/docs/releases/supported-releases/#support-status-of-istio-releases) для отримання інформації про стан конкретних випусків.

Щоб допомогти визначити, чи потрібно використовувати сумісність версій, можна скористатися командою `istioctl x precheck` з прапорцем `--from-version`. Наприклад, якщо ви оновлюєтесь з версії {{< istio_previous_version >}}:

{{< text shell >}}
$ istioctl x precheck --from-version {{< istio_previous_version >}}
Warning [IST0168] (DestinationRule default/tls) The configuration "ENABLE_AUTO_SNI" changed in release 1.20: previously, no SNI would be set; now it will be automatically set. Or, install with `--set compatibilityVersion=1.20` to retain the old default.
Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/v1.21/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}
