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

* **Управління трафіком**: HTTP-маршрутизація та балансування навантаження, аварійне відновлення, обмеження швидкості, введення збоїв, повторні спроби, тайм-аути
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

### Шлюзи входу та waypoint {#ingress-and-waypoints}

Мітка `istio.io/use-waypoint` керує трафіком **схід-захід**: запити від інших podʼів у mesh до позначеного міткою простору імен, сервісу або робочого навантаження надсилаються через waypoint призначення для застосування політик та телеметрії на рівні 7.

Трафік від **шлюзу входу Istio** до цього `Service` моделюється окремо. Стандартно трафік, що походить від шлюзу входу, **не** використовуватиме waypoint сервісу призначення, навіть якщо `istio.io/use-waypoint` встановлено на сервісі або просторі імен.

Щоб направити вхідний трафік через той самий waypoint, що й трафік mesh, встановіть **`istio.io/ingress-use-waypoint`** у значення `true` в Kubernetes `Service`, або в `Namespace`, щоб застосувати до всіх сервісів у цьому просторі імен (підтримується починаючи з Istio 1.25). Див. довідник [міток ресурсів](/docs/reference/config/labels/#IoIstioIngressUseWaypoint) для підтримуваних типів ресурсів.

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/ingress-use-waypoint=true
service/reviews labeled
{{< /text >}}

{{< tip >}}
Увімкнення цього шляху призводить до **обробки на рівні 7 як на шлюзі входу, так і на waypoint** (дворівнева схема шлюзів). Враховуйте правила авторизації, затримку та метрики для обох переходів.
{{< /tip >}}

Панель управління застосовує цю поведінку лише тоді, коли **`ENABLE_INGRESS_WAYPOINT_ROUTING`** увімкнено для istiod; стандартно вона дорівнює `false`. Див. [`ENABLE_INGRESS_WAYPOINT_ROUTING`](/docs/reference/commands/pilot-discovery/#enable-ingress-waypoint-routing) у довіднику змінних середовища pilot-discovery.

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

Розгорніть waypoint з назвою `reviews-v2-pod-waypoint` для podʼа `reviews-v2`.

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

### Вимога проходження трафіку через waypoint {#require-waypoint}

Мітка `istio.io/use-waypoint` фіксує ваш намір надсилати трафік через waypoint, але сама по собі вона не гарантує, що це відбуватиметься. ztunnel маршрутизує трафік безпосередньо до призначення, а не відхиляє запит, коли:

* вказаний waypoint не існує або не має адреси; або
* тип трафіку не збігається з типом трафіку, який обробляє waypoint; наприклад, запит, надісланий безпосередньо до робочого навантаження (IP podʼа або VM), коли waypoint обробляє лише трафік сервісів, що є [стандартним](#waypoint-traffic-types).

У будь-якому випадку будь-яка політика рівня 7, яку мав би застосовувати waypoint, ніколи не набуває чинності, і трафік передається так, ніби waypoint не налаштовано.

Якщо застосування політик рівня 7 waypoint є вимогою безпеки, зробіть waypoint обовʼязковим за допомогою `AuthorizationPolicy`, яка дозволяє лише ідентичність waypoint. Waypoint використовує службовий обліковий запис, названий за його `Gateway`, тому політика на робочих навантаженнях призначення, яка дозволяє лише цю ідентичність, відхиляє будь-якого клієнта, який досягає їх без попереднього проходження через waypoint. Продовжуючи з waypoint `reviews-svc-waypoint` з прикладу вище:

{{< text syntax=yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-waypoint
  namespace: default
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/reviews-svc-waypoint
{{< /text >}}

Ця політика використовує `selector` робочого навантаження, а не `targetRef`, тому вона застосовується на рівні 4 за допомогою ztunnel. Таким чином, вона діє в обох випадках оминання: коли waypoint недоступний, і коли клієнт звертається безпосередньо до робочого навантаження.

### Перемикання трафіку між waypoint {#waypoint-canary}

{{< warning >}}
Перемикання трафіку між waypoint підтримується починаючи з Istio 1.31 і вважається [альфа-версією](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md). Мітки, анотація та поведінка можуть змінюватися в майбутніх випусках.
{{< /warning >}}

Зміна мітки `istio.io/use-waypoint` на сервісі переміщує весь його трафік на новий waypoint одразу. Щоб поступово перемістити сервіс між двома waypoint, наприклад, для перевірки нової ревізії waypoint під час оновлення, вкажіть другий _канарковий_ waypoint поруч із основним і надайте йому частку трафіку сервісу. Конфігурація повністю розміщується на сервісі призначення: клієнти про неї не знають, і другий `Service` не потрібен.

| Назва | Тип | Призначення |
| --- | --- | --- |
| [`istio.io/use-waypoint-canary`](/docs/reference/config/labels/#IoIstioUseWaypointCanary) | мітка | Назва канаркового waypoint `Gateway`. |
| [`istio.io/use-waypoint-canary-namespace`](/docs/reference/config/labels/#IoIstioUseWaypointCanaryNamespace) | мітка | Простір імен канаркового waypoint, якщо він не є простором імен сервісу. |
| [`istio.io/use-waypoint-canary-weight`](/docs/reference/config/annotations/#IoIstioUseWaypointCanaryWeight) | анотація | Частка трафіку, що надсилається до канаркового waypoint, як ціле число від 0 до 100. Основний waypoint отримує решту. Стандартно дорівнює 0. |

Продовжуючи з сервісом `reviews` з прикладу вище, розгорніть другий waypoint і надішліть 5% трафіку сервісу на нього, залишивши решту 95% на `reviews-svc-waypoint`:

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint-v2
waypoint default/reviews-svc-waypoint-v2 applied
{{< /text >}}

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint-canary=reviews-svc-waypoint-v2
$ kubectl annotate service reviews istio.io/use-waypoint-canary-weight=5
{{< /text >}}

Збільшуйте вагу, коли набираєтеся впевненості в канарковому waypoint. Коли канарковий waypoint оброблятиме весь трафік, просувайте його, зробивши його основним waypoint і видаливши канаркову конфігурацію:

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint-v2 --overwrite
$ kubectl label service reviews istio.io/use-waypoint-canary-
$ kubectl annotate service reviews istio.io/use-waypoint-canary-weight-
{{< /text >}}

Щоб відкотитися у будь-який момент, видаліть канаркову мітку. Сервіс повернеться до надсилання всього свого трафіку через основний waypoint.

#### Підтримувані ресурси {#supported-resources}

Канаркові мітки та анотація підтримуються на `Service`, `ServiceEntry` та `Namespace`. На відміну від `istio.io/use-waypoint`, вони **не** підтримуються на `Pod` або `WorkloadEntry`: розподіл визначається на рівні сервісу, щоб він поводився однаково для трафіку mesh та вхідного трафіку.

Канаркова конфігурація, налаштована на просторі імен, застосовується лише до сервісів, які також успадковують свій основний waypoint з цього простору імен. Якщо сервіс встановлює власний `istio.io/use-waypoint`, він також повинен встановити власну канаркову конфігурацію; канаркові мітки простору імен ігноруються для цього сервісу.

Обидва waypoint повинні мати можливість обслуговувати сервіс. Кожен з них повинен бути готовим, дозволяти прикріплення з простору імен сервісу та обробляти трафік типу `service` або `all`.

#### До чого застосовується вага {#what-the-weight-applies-to}

* **Трафік Mesh** розподіляється за допомогою {{< gloss >}}ztunnel{{< /gloss >}} **для кожного з’єднання**: вага — це частка _нових_ з’єднань, які обирають канаркову версію. Вже встановлені з’єднання ніколи не переміщуються, тому сервіс, клієнти якого підтримують довготривалі з’єднання, наблизиться до налаштованої ваги лише тоді, коли ці клієнти перепідключаться. З тієї ж причини спостережуваний розподіл є приблизним і має сенс лише для великої кількості з’єднань.
* **Вхідний трафік** розподіляється шлюзом входу **за кожним запитом** і лише для сервісів, які підключилися за допомогою `istio.io/ingress-use-waypoint`, як описано в розділі [Шлюзи входу та waypoints](#ingress-and-waypoints). Без такого підключення вхідний трафік продовжує оминати обидва waypoints.

Розподіл трафіку Mesh вимагає ztunnel від Istio 1.31 або новішої версії. Поки оновлюється панель даних, вузли, які все ще працюють на старішому ztunnel, надсилають усі свої з’єднання до основного waypoint, тому розподіл у Mesh відстає від налаштованої ваги, доки всі вузли не будуть оновлені. Розподіл вхідного трафіку не залежить від ztunnel.

#### Налаштування, прикріплене до waypoint {#configuration-attached-to-the-waypoint}

Обидва waypoint обслуговують той самий сервіс, тому будь-яке налаштування, яке має залишатися в силі під час переключення, має застосовуватися до обох. Політики та маршрути, які орієнтовані на `Service`, такі як `AuthorizationPolicy` або `HTTPRoute` з сервісом як `parentRef`, застосовуються тим waypoint, який обробляє трафік, і не потребують дублювання.

Налаштування, прикріплене безпосередньо до waypoint `Gateway`, — це інша справа. `WasmPlugin`, який обирає waypoint, або політика, чиє `targetRef` називає `Gateway`, застосовується лише до цього waypoint. Скопіюйте його на канарку перед переключенням трафіку, інакше частка трафіку, що проходить через канарку, обробляється іншим набором політик.

#### Неприпустима конфігурація {#invalid-configuration}

Непридатна канаркова версія не є фатальною. Сервіс продовжує використовувати лише свій основний waypoint, а причина повідомляється в стані `istio.io/WaypointBound` на сервісі:

{{< text syntax=bash >}}
$ kubectl get service reviews -o jsonpath='{.status.conditions}'
{{< /text >}}

Цей відкат застосовується, коли канарковий waypoint не існує, не готовий, не дозволяє прикріплення з простору імен сервісу або не може обробляти трафік сервісу; коли вага не є цілим числом від 0 до 100 (`CanaryInvalidWeight`); і коли канаркова версія вказує той самий waypoint, що й основний (`CanarySameAsPrimary`).

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
