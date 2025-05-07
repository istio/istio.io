---
title: Захист та візуалізація роботи застосунку
description: Увімкніть режим оточення та захистіть звʼязок між застосунками.
weight: 3
owner: istio/wg-networking-maintainers
test: yes
---

Додавання застосунків до ambient mesh є дуже простим: вам потрібно лише додати мітку до простору імен, де розгорнуто застосунок. Додавши застосунки до мережі, ви автоматично забезпечите їхню комунікацію, а Istio почне збирати TCP-метрики. І ні, вам не потрібно перезапускати чи повторно розгортати застосунки!

## Додавання Bookinfo до сервісної мережі {#add-bookinfo-to-the-mesh}

Щоб дозволити всім podʼам у вказаному просторі імен бути частиною ambient mesh, просто додайте мітку до простору імен:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
namespace/default labeled
{{< /text >}}

Вітаємо! Ви успішно додали всі podʼи в просторі імен `default` до ambient mesh. 🎉

Якщо ви відкриєте застосунок Bookinfo у вашому оглядачі, ви побачите ту ж саму сторінку продукту, як і раніше. Різниця в тому, що тепер комунікація між podʼами pfcnjceyre Bookinfo зашифрована за допомогою mTLS. Додатково, Istio збирає TCP-метрики для всього трафіку між podʼами.

{{< tip >}}
Тепер у вас є mTLS-шифрування між усіма вашими podʼами — без перезапуску чи повторного розгортання будь-яких застосунків!
{{< /tip >}}

## Візуалізація застосунку та метрик {#visualize-the-application-and-metrics}

Використовуючи інфопанель Istio Kiali та систему метрик Prometheus, ви можете візуалізувати застосунок Bookinfo. Розгорніть їх обидва:

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f @samples/addons/prometheus.yaml@
$ kubectl apply -f @samples/addons/kiali.yaml@
{{< /text >}}

Ви можете отримати доступ до дашборду Kiali, запустивши наступну команду:

{{< text syntax=bash snip_id=none >}}
$ istioctl dashboard kiali
{{< /text >}}

Надішліть трохи трафіку до застосунку Bookinfo, щоб Kiali згенерувала графік:

{{< text bash >}}
$ for i in $(seq 1 100); do curl -sSI -o /dev/null http://localhost:8080/productpage; done
{{< /text >}}

Далі, натисніть на графік трафіку, і оберіть "Default" в меню ""Select Namespaces". Ви повинні побачити застосунок Bookinfo:

{{< image link="./kiali-ambient-bookinfo.png" caption="Дашборд Kiali" >}}

{{< tip >}}
Якщо ви не бачите графік трафіку, спробуйте знову надіслати трафік до застосунку Bookinfo та переконайтеся, що ви вибрали простір імен **default** у меню **Namespace** в Kiali.

Щоб побачити статус mTLS між сервісами, натисніть меню **Display** та виберіть **Security**.
{{</ tip >}}

Якщо ви натиснете на лінію, що зʼєднує два сервіси в дашборді, ви зможете побачити метрики вхідного та вихідного трафіку, зібрані Istio.

{{< image link="./kiali-tcp-traffic.png" caption="L4 трафік" >}}

Окрім TCP-метрик, Istio створив сильну ідентичність для кожного сервісу: SPIFFE ID. Цю ідентичність можна використовувати для створення політик авторизації.

## Подальші кроки {#next-steps}

Тепер, коли ми призначили ідентичності сервісам, [застосуємо політики авторизації](/docs/ambient/getting-started/enforce-auth-policies/), щоб забезпечити доступ до застосунку.
