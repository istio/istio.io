---
title: Налаштування waypoint-проксі
description: Отримайте повний набір функцій Istio з додатковими проксі 7-го рівня.
weight: 30
aliases:
  - /uk/docs/ops/ambient/usage/waypoint
  - /latest/uk/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: yes
---

**Waypoint-проксі** є необовʼязковим розгортанням проксі на основі Envoy, що додає обробку на рівні 7 (L7) для визначеного набору робочих навантажень.

Waypoint-проксі встановлюються, оновлюються та масштабуються незалежно від застосунків; власник застосунку не повинен бути обізнаний про їх існування. У порівнянні з режимом {{< gloss "панель даних" >}}панелі даних{{< /gloss >}} на основі sidecar, який запускає екземпляр проксі Envoy поруч з кожним робочим навантаженням, кількість необхідних проксі може бути суттєво зменшена.

Waypoint-проксі або їх набір може бути спільним для кількох застосунків, що мають спільний контур безпеки. Це можуть бути всі екземпляри конкретного робочого навантаження або всі робочі навантаження в просторі імен.

На відміну від {{< gloss "sidecar" >}}режиму sidecar{{< /gloss >}}, у режимі ambient політики виконуються **точкою призначення**. У багатьох аспектах waypoint діє як шлюз до ресурсу (простір імен, сервіс або pod). Istio забезпечує, щоб увесь трафік, що надходить до ресурсу, проходив через waypoint, який потім забезпечує дотримання всіх політик для цього ресурсу.

## Чи потрібен вам waypoint-проксі? {#do-you-need-a-waypoint-proxy}

Багаторівневий підхід режиму оточення дозволяє користувачам впроваджувати Istio більш поступово, плавно переходячи від відсутності mesh, до захищеного L4 overlay і до повної обробки L7.

Більшість функцій режиму ambient забезпечуються вузловим проксі ztunnel. Ztunnel обмежується обробкою трафіку на рівні 4 (L4), тому він може безпечно працювати як спільний компонент.

Коли ви налаштовуєте перенаправлення на waypoint, трафік буде переспрямовуватись ztunnel до waypoint. Якщо вашим застосункам потрібні будь-які з наступних функцій mesh на рівні L7, вам знадобиться waypoint-проксі:

* **Управління трафіком**: HTTP-маршрутизація та балансування навантаження, аварійне відновлення, обмеження швидкості, введення збоїів, повторні спроби, тайм-аути
* **Безпека**: Розширені політики авторизації на основі L7-примітивів, таких як тип запиту або HTTP-заголовок
* **Спостережуваність**: HTTP-метрики, логування доступу, трейсинг

## Розгортання waypoint-проксі {#deploy-a-waypoint-proxy}

Waypoint-проксі розгортаються за допомогою ресурсів Kubernetes Gateway.

{{< boilerplate gateway-api-install-crds >}}

Ви можете використовувати підкоманди istioctl waypoint для створення, застосування або перегляду цих ресурсів.

Після розгортання waypoint весь простір імен (або будь-які обрані вами сервіси чи podʼи) мають бути [зареєстровані](#useawaypoint) для використання waypoint.

Перш ніж розгортати waypoint-проксі для конкретного простору імен, переконайтеся, що простір імен позначено міткою `istio.io/dataplane-mode: ambient`:

{{< text syntax=bash snip_id=check_ns_label >}}
$ kubectl get ns -L istio.io/dataplane-mode
NAME              STATUS   AGE   DATAPLANE-MODE
istio-system      Active   24h
default           Active   24h   ambient
{{< /text >}}

`istioctl` може згенерувати ресурс Kubernetes Gateway для waypoint-проксі. Наприклад, щоб згенерувати waypoint-проксі з назвою `waypoint` для простору імен `default`, що може обробляти трафік для сервісів у цьому просторі імен:

{{< text syntax=bash snip_id=gen_waypoint_resource >}}
$ istioctl waypoint generate --for service -n default
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Зверніть увагу, що ресурс Gateway має `gatewayClassName` з `istio-waypoint`, який є екземпляром waypoint, керованого Istio. Ресурс Gateway позначено як `istio.io/waypoint-for: service`, що вказує на те, що waypoint може обробляти трафік для сервісів, що є стандартним значенням.

Для безпосереднього розгортання waypoint-проксі використовуйте `apply` замість `generate`:

{{< text syntax=bash snip_id=apply_waypoint >}}
$ istioctl waypoint apply -n default
waypoint default/waypoint applied
{{< /text >}}

Або ви можете розгорнути згенерований ресурс Gateway:

{{< text syntax=bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

Після застосування ресурсу Gateway, Istiod буде контролювати цей ресурс, розгортати та керувати відповідним розгортанням і обслуговуванням waypoint для користувачів автоматично.

### Типи трафіку waypoint {#waypoint-traffic-types}

Стандартно waypoint буде обробляти тільки трафік, що призначений для **сервісів** у своєму просторі імен. Це рішення було прийняте тому, що трафік, спрямований лише до podʼа, є рідкісним і часто використовується для внутрішніх цілей, таких як збір даних Prometheus, а додаткове навантаження на обробку на рівні L7 може бути небажаним.

Також можливо, щоб waypoint обробляв весь трафік, лише трафік, спрямований безпосередньо до **робочих навантажень** (podʼів або віртуальних машин) у кластері, або жоден трафік. Типи трафіку, які будуть перенаправлені до waypoint, визначаються міткою `istio.io/waypoint-for` на обʼєкті `Gateway`.

Використовуйте аргумент `--for` у команді `istioctl waypoint apply`, щоб змінити типи трафіку, які можуть бути перенаправлені на waypoint:

| Значення `waypoint-for` | Початковий тип призначення |
| ----------------------- | -------------------------- |
| `service`               | Сервіси Kubernetes |
| `workload`              | IP podʼів або IP віртуальних машин |
| `all`                   | Трафік як сервісів, так і робочих навантажень |
| `none`                  | Жоден трафік (корисно для тестування) |

Вибір waypoint здійснюється на основі типу призначення, `service` або `workload`, до якого трафік був _спочатку адресований_. Якщо трафік адресовано до сервісу, який не має waypoint, перехід через waypoint не відбудеться: навіть якщо кінцевий робочий процес, до якого він потрапляє, _має_ прикріплений waypoint.

## Використання waypoint-проксі {#useawaypoint}

Коли waypoint-проксі розгорнуто, він не використовується жодними ресурсами, поки ви явно не налаштуєте ці ресурси на його використання.

Щоб увімкнути використання waypoint для простору імен, сервісу або podʼа, додайте мітку `istio.io/use-waypoint` з назвою waypoint як значенням.

{{< tip >}}
Більшість користувачів захочуть застосувати waypoint до всього простору імен, і ми рекомендуємо почати з цього підходу.
{{< /tip >}}

Якщо ви використовуєте `istioctl` для розгортання waypoint для простору імен, ви можете використовувати параметр `--enroll-namespace`, щоб автоматично позначити простір імен:

{{< text syntax=bash snip_id=enroll_ns_waypoint >}}
$ istioctl waypoint apply -n default --enroll-namespace
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Альтернативно, ви можете додати мітку `istio.io/use-waypoint: waypoint` до простору імен `default` за допомогою `kubectl`:

{{< text syntax=bash >}}
$ kubectl label ns default istio.io/use-waypoint=waypoint
namespace/default labeled
{{< /text >}}

Після того як простір імен буде зареєстрований для використання waypoint, будь-які запити від podʼів, що використовують режим панелі даних ambient, до будь-якого сервісу, що працює в цьому просторі імен, будуть направлені через waypoint для обробки на рівні L7 та застосування політик.

Якщо вам потрібна більша деталізація, ніж використання waypoint для всього простору імен, ви можете зареєструвати лише конкретний сервіс або pod для використання waypoint. Це може бути корисно, якщо вам потрібні функції рівня L7 лише для деяких сервісів у просторі імен, якщо ви хочете, щоб розширення, таке як `WasmPlugin`, застосовувалось лише до конкретного сервісу, або якщо ви звертаєтесь до [headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) Kubernetes за IP-адресою podʼа.

{{< tip >}}
Якщо мітка `istio.io/use-waypoint` існує як на просторі імен, так і на сервісі, мітка сервісу має пріоритет над міткою простору імен, за умови, що waypoint для сервісу може обробляти трафік типу `service` або `all`. Подібним чином, мітка на podʼі має пріоритет над міткою простору імен.
{{< /tip >}}

### Налаштування сервісу для використання конкретної waypoint {#configure-a-service-to-use-a-specific-waypoint}

Використовуючи сервіс з прикладу [застосунку bookinfo](/docs/examples/bookinfo/), ми можемо розгорнути waypoint з назвою `reviews-svc-waypoint` для сервісу `reviews`:

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint
waypoint default/reviews-svc-waypoint applied
{{< /text >}}

Позначте сервіс `reviews`, щоб він використовував waypoint `reviews-svc-waypoint`:

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint
service/reviews labeled
{{< /text >}}

Будь-які запити від podʼів у mesh до сервісу `reviews` тепер будуть направлятись через waypoint `reviews-svc-waypoint`.

### Налаштування podʼа для використання конкретного waypoint {#configure-a-pod-to-use-a-specific-waypoint}

Розгорніть waypoint х назвою `reviews-v2-pod-waypoint` для podʼа `reviews-v2`.

{{< tip >}}
Зазначимо, що стандартно waypointʼи орієнтовані на сервіси; оскільки ми явно хочемо орієнтуватися на pod, нам потрібно використовувати мітку `istio.io/waypoint-for: workload`, яку можна згенерувати за допомогою параметра `--for workload` для istioctl.
{{< /tip >}}

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-v2-pod-waypoint --for workload
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

Позначте pod `reviews-v2`, щоб він використовував waypoint `reviews-v2-pod-waypoint`:

{{< text syntax=bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

Будь-які запити від podʼів в ambient mesh до IP podʼа `reviews-v2` тепер будуть направлені через waypoint `reviews-v2-pod-waypoint` для обробки на рівні L7 та застосування політик.

{{< tip >}}
Оригінальний тип призначення трафіку використовується для визначення, чи буде використано waypoint сервісу або робочого процесу. Завдяки використанню оригінального типу призначення, ambient mesh уникає подвійного проходження через waypoint, навіть якщо як сервіс, так і робочий процес мають прикріплені waypoint. Наприклад, трафік, адресований сервісу, навіть якщо в кінцевому підсумку його призначенням є IP-адреса podʼа, завжди розглядається ambient mesh як трафік до сервісу і використовуватиме waypoint, прикріплений до сервісу.
{{< /tip >}}

## Використання waypoint в різних просторах імен {#usewaypointnamespace}

Стандартно проксі waypoint доступний для ресурсів у тому ж просторі імен. Починаючи з Istio 1.23, стало можливим використовувати waypoint в інших просторах імен. У цьому розділі ми розглянемо конфігурацію шлюзу, необхідну для увімкнення використання waypoint у різних просторах імен, а також як налаштувати ваші ресурси для використання waypoint з іншого простору імен.

### Налаштування waypoint для використання у різних просторах імен {#configure-a-waypoint-for-cross-namespace-use}

Щоб увімкнути використання waypoint у різних просторах імен, слід налаштувати `Gateway` для [дозволу маршрутів](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.AllowedRoutes) з інших просторів імен.

{{< tip >}}
Ключове слово `All` можна вказати як значення для `allowedRoutes.namespaces.from`, щоб дозволити маршрути з будь-якого простору імен.
{{< /tip >}}

Наступний `Gateway` дозволить ресурсам у просторі імен з назвою "cross-namespace-waypoint-consumer" використовувати цей `egress-gateway`:

{{< text syntax=yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: egress-gateway
  namespace: common-infrastructure
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: cross-namespace-waypoint-consumer
{{< /text >}}

### Налаштування ресурсів для використання waypoint проксі з іншого простору імен {#configure-resources-to-use-a-cross-namespace-waypoint-proxy}

Стандартно, панель управління Istio буде шукати waypoint, вказаний за допомогою мітки `istio.io/use-waypoint`, у тому ж просторі імен, що й ресурс, до якого застосовано цю мітку. Можна використовувати waypoint в іншому просторі імен, додавши нову мітку `istio.io/use-waypoint-namespace`. `istio.io/use-waypoint-namespace` працює для всіх ресурсів, які підтримують мітку `istio.io/use-waypoint`. Разом ці дві мітки вказують відповідно імʼя та простір імен вашого waypoint. Наприклад, щоб налаштувати `ServiceEntry` з назвою `istio-site` для використання waypoint з назвою `egress-gateway` у просторі імен з назвою `common-infrastructure`, можна скористатися такими командами:

{{< text syntax=bash >}}
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint=egress-gateway
serviceentries.networking.istio.io/istio-site labeled
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint-namespace=common-infrastructure
serviceentries.networking.istio.io/istio-site labeled
{{< /text >}}

### Очищення {#cleaning-up}

Ви можете видалити всі waypoint з простору імен, виконавши наступні дії:

{{< text syntax=bash snip_id=delete_waypoint >}}
$ istioctl waypoint delete --all -n default
$ kubectl label ns default istio.io/use-waypoint-
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
