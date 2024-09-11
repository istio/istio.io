---
title: Діагностика вашої конфігурації з Istioctl Analyze
description: Показує, як використовувати `istioctl analyze` для виявлення потенційних проблем у вашій конфігурації.
weight: 40
keywords: [istioctl, debugging, kubernetes]
owner: istio/wg-user-experience-maintainers
test: yes
---

`istioctl analyze` є інструментом діагностики, який може виявляти потенційні проблеми з вашою конфігурацією Istio. Він може працювати з живим кластером або з набором локальних конфігураційних файлів. Також він може працювати з комбінацією обох, що дозволяє виявити проблеми до того, як ви застосуєте зміни до кластера.

## Початок роботи за хвилину {#getting-started-in-under-a-minute}

Ви можете проаналізувати ваш поточний живий кластер Kubernetes, запустивши:

{{< text syntax=bash snip_id=analyze_all_namespaces >}}
$ istioctl analyze --all-namespaces
{{< /text >}}

І це все! Ви отримаєте рекомендації, які можуть бути застосовані.

Наприклад, якщо ви забули увімкнути інʼєкцію Istio (дуже поширена проблема), ви отримаєте таке повідомлення 'Info':

{{< text syntax=plain snip_id=analyze_all_namespace_sample_response >}}
Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

Виправте проблему:

{{< text syntax=bash snip_id=fix_default_namespace >}}
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

Потім спробуйте ще раз:

{{< text syntax=bash snip_id=try_with_fixed_namespace >}}
$ istioctl analyze --namespace default
✔ No validation issues found when analyzing namespace: default.
{{< /text >}}

## Аналіз живих кластерів, локальних файлів або обох {#analyzing-live-clusters-local-files-or-both}

Аналізуйте поточний живий кластер, імітуючи ефект застосування додаткових yaml-файлів, таких як `bookinfo-gateway.yaml` та `destination-rule-all.yaml` у директорії `samples/bookinfo/networking`:

{{< text syntax=bash snip_id=analyze_sample_destrule >}}
$ istioctl analyze @samples/bookinfo/networking/bookinfo-gateway.yaml@ @samples/bookinfo/networking/destination-rule-all.yaml@
Error [IST0101] (Gateway default/bookinfo-gateway samples/bookinfo/networking/bookinfo-gateway.yaml:9) Referenced selector not found: "istio=ingressgateway"
Error [IST0101] (VirtualService default/bookinfo samples/bookinfo/networking/bookinfo-gateway.yaml:41) Referenced host not found: "productpage"
Error: Analyzers found issues when analyzing namespace: default.
See https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}

Проаналізуйте всю теку `networking`:

{{< text syntax=bash snip_id=analyze_networking_directory >}}
$ istioctl analyze samples/bookinfo/networking/
{{< /text >}}

Проаналізуйте всі yaml-файли в теці `networking`:

{{< text syntax=bash snip_id=analyze_all_networking_yaml >}}
$ istioctl analyze samples/bookinfo/networking/*.yaml
{{< /text >}}

Вищезгадані приклади проводять аналіз на живому кластері. Інструмент також підтримує проведення аналізу набору локальних конфігураційних файлів Kubernetes або комбінації локальних файлів і живого кластера. При аналізі набору локальних файлів, файл-сет очікується бути повністю самодостатнім. Зазвичай це використовується для аналізу всього набору конфігураційних файлів, які мають бути розгорнуті в кластер. Щоб скористатися цією функцією, просто додайте прапорець `--use-kube=false`.

Аналізуйте всі yaml-файли в теці `networking`:

{{< text syntax=bash snip_id=analyze_all_networking_yaml_no_kube >}}
$ istioctl analyze --use-kube=false samples/bookinfo/networking/*.yaml
{{< /text >}}

Ви можете виконати `istioctl analyze --help`, щоб побачити повний набір опцій.

## Розширені можливості {#advanced}

### Увімкнення повідомлень про перевірку для статусу ресурсів {#enabling-validation-messages-for-resource-status}

{{< boilerplate experimental-feature-warning >}}

Починаючи з версії 1.5, Istio можна налаштувати для проведення аналізу конфігурації разом з розподілом конфігурації, за який він в основному відповідає, через прапорець `istiod.enableAnalysis`. Цей аналіз використовує ту ж саму логіку та повідомлення про помилки, як при використанні `istioctl analyze`. Повідомлення про перевірку з аналізу записуються в підресурс статусу відповідного ресурсу Istio.

Наприклад, якщо у вас є неправильно налаштований шлюз у вашій віртуальній службі "ratings", виконання `kubectl get virtualservice ratings` покаже вам щось подібне:

{{< text syntax=yaml snip_id=vs_yaml_with_status >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
...
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
...
status:
  observedGeneration: "1"
  validationMessages:
  - documentationUrl: https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis/ist0101/
    level: ERROR
    type:
      code: IST0101
{{< /text >}}

`enableAnalysis` працює у фоновому режимі та буде тримати поле статусу ресурсу в актуальному стані з його поточним статусом перевірки. Зверніть увагу, що це не є заміною для `istioctl analyze`:

- Не всі ресурси мають власне поле статусу (наприклад, ресурси Kubernetes `namespace`), тому повідомлення, прикріплені до цих ресурсів, не покажуть повідомлення про перевірку.
- `enableAnalysis` працює тільки на версіях Istio, починаючи з 1.5, тоді як `istioctl analyze` можна використовувати з більш старими версіями.
- Хоча це спрощує перегляд помилок у конкретному ресурсі, важче отримати загальну картину статусу перевірки в Mesh.

Ви можете увімкнути цю функцію за допомогою:

{{< text syntax=bash snip_id=install_with_custom_config_analysis >}}
$ istioctl install --set values.global.istiod.enableAnalysis=true
{{< /text >}}

### Ігнорування специфічних повідомлень аналізатора через CLI {#ignoring-specific-analyzer-messages-via-cli}

Іноді може бути корисно приховати або ігнорувати повідомлення аналізатора в певних випадках. Наприклад, уявіть ситуацію, коли повідомлення видається про ресурс, до якого у вас немає дозволів на оновлення:

{{< text syntax=bash snip_id=analyze_k_frod >}}
$ istioctl analyze -k --namespace frod
Info [IST0102] (Namespace frod) The namespace is not enabled for Istio injection. Run 'kubectl label namespace frod istio-injection=enabled' to enable it, or 'kubectl label namespace frod istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

Оскільки у вас немає дозволів на оновлення простору імен, ви не можете цього розвʼязати, додавши анотацію до простору імен. Натомість ви можете вказати `istioctl analyze`, щоб подавити це повідомлення на ресурс:

{{< text syntax=bash snip_id=analyze_suppress0102 >}}
$ istioctl analyze -k --namespace frod --suppress "IST0102=Namespace frod"
✔ No validation issues found when analyzing namespace: frod.
{{< /text >}}

Синтаксис для придушення такий ж, як і у `istioctl` при посиланні на ресурси: `<kind> <name>.<namespace>`, або просто `<kind> <name>` для ресурсів з кластером, таких як `Namespace`. Якщо ви хочете придушити кілька обʼєктів, ви можете повторити аргумент `--suppress` або використовувати шаблони:

{{< text syntax=bash snip_id=analyze_suppress_frod_0107_baz >}}
$ # Подавити код IST0102 на простір імен frod та IST0107 на всі контейнери в просторі імен baz
$ istioctl analyze -k --all-namespaces --suppress "IST0102=Namespace frod" --suppress "IST0107=Pod *.baz"
{{< /text >}}

### Ігнорування специфічних повідомлень аналізатора через анотації {#ignoring-specific-analyzer-messages-via-annotations}

Ви також можете ігнорувати специфічні повідомлення аналізатора, використовуючи анотацію на ресурсі. Наприклад, щоб ігнорувати код IST0107 (`MisplacedAnnotation`) на ресурсі `deployment/my-deployment`:

{{< text syntax=bash snip_id=annotate_for_deployment_suppression >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107
{{< /text >}}

Щоб ігнорувати кілька кодів для ресурсу, розділіть кожен код комою:

{{< text syntax=bash snip_id=annotate_for_deployment_suppression_107 >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107,IST0002
{{< /text >}}

## Допоможіть нам покращити цей інструмент {#helping-us-improve-this-tool}

Ми продовжуємо додавати нові можливості для аналізу і будемо вдячні за вашу допомогу в ідентифікації нових сценаріїв використання. Якщо ви виявили якусь проблему з конфігурацією Istio, яка спричинила труднощі, відкрийте issue і дайте нам знати. Можливо, ми зможемо автоматично помічати цю проблему, щоб інші могли виявити та уникнути її з самого початку.

Щоб це зробити, [відкрийте issue](https://github.com/istio/istio/issues), описуючи ваш сценарій. Наприклад:

- Перегляньте всі віртуальні сервіси
- Для кожної перевірте їх список шлюзів
- Якщо деякі шлюзи не існують, виведіть помилку

У нас вже є аналізатор для цього конкретного сценарію, тому це просто приклад, щоб ілюструвати, яку інформацію ви повинні надати.

## Питання та відповіді {#qa}

- **Яку версію Istio підтримує цей інструмент?**

    Як і інші інструменти `istioctl`, ми зазвичай рекомендуємо використовувати завантажену версію, яка відповідає версії, розгорнутій у вашому кластері.

    Тимчасово, аналіз зазвичай є зворотно сумісним, тому ви можете, наприклад, запустити версію {{< istio_version >}} інструменту `istioctl analyze` на кластері, що використовує старішу версію Istio 1.x, і очікувати корисний відгук. Правила аналізу, які не мають сенсу для старішої версії Istio, будуть пропущені.

    Якщо ви вирішите використовувати найновіший `istioctl` для аналізу в кластері, що працює на старішій версії Istio, ми рекомендуємо зберігати його в окремій теці від версії бінарного файлу, що використовується для управління вашою розгорнутою версією Istio.

- **Які аналізатори підтримуються сьогодні?**

    Ми все ще працюємо над документуванням аналізаторів. Тим часом ви можете переглянути всі аналізатори в [сирцях Istio]({{< github_tree >}}/pkg/config/analysis/analyzers).

    Ви також можете переглянути, які [повідомлення про аналіз конфігурації](/docs/reference/config/analysis/) підтримуються, щоб отримати уявлення про те, що наразі охоплюється.

- **Чи може аналіз завдати шкоди моєму кластеру?**

    Аналіз ніколи не змінює стан конфігурації. Це операція тільки для читання, яка ніколи не змінює стан кластера.

- **А як щодо аналізу, що виходить за межі конфігурації?**

    На сьогодні аналіз базується виключно на конфігурації Kubernetes, але в майбутньому ми хотіли б розширити його можливості. Наприклад, ми могли б дозволити аналізаторам також переглядати логи для створення рекомендацій.

- **Де можна дізнатися, як виправити помилки, які я отримую?**

    Набір [повідомлень про аналіз конфігурації](/docs/reference/config/analysis/) містить описи кожного повідомлення разом з запропонованими виправленнями.
