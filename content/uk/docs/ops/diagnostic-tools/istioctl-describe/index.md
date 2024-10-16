---
title: Зрозумійте свою Mesh мережу за допомогою Istioctl Describe
description: Показує, як використовувати istioctl describe для перевірки конфігурацій podʼа у вашій mesh мережі.
weight: 30
keywords: [traffic-management, istioctl, debugging, kubernetes]
aliases:
  - /docs/ops/troubleshooting/istioctl-describe
owner: istio/wg-user-experience-maintainers
test: no
---

{{< boilerplate experimental-feature-warning >}}

В Istio 1.3 ми включили команду [`istioctl experimental describe`](/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod). Ця команда CLI надає інформацію, необхідну для розуміння конфігурації, що впливає на {{< gloss >}}pod{{< /gloss >}}. Цей посібник показує, як використовувати цю експериментальну команду, щоб перевірити, чи є pod у mesh і перевірити його конфігурацію.

Основне використання команди виглядає наступним чином:

{{< text bash >}}
$ istioctl experimental describe pod <pod-name>[.<namespace>]
{{< /text >}}

Додавання простору імен до імені podʼа має такий же ефект, як і використання опції `-n` в `istioctl` для вказівки не стандартного простору імен.

{{< tip >}}
Як і всі інші команди `istioctl`, ви можете замінити `experimental` на `x` для зручності.
{{< /tip >}}

Цей посібник передбачає, що ви розгорнули демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/) у вашій mesh. Якщо ви цього ще не зробили, [запустіть сервіси застосунку](/docs/examples/bookinfo/#start-the-application-services) і [визначте IP і порт ingress](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) перед продовженням.

## Перевірте, чи є pod у mesh {#verify-a-pod-is-in-the-mesh}

Команда `istioctl describe` повертає попередження, якщо {{< gloss >}}Envoy{{< /gloss >}} проксі не присутній у podʼі або якщо проксі не запущено. Крім того, команда попереджає, якщо деякі з [вимог Istio для podʼів](/docs/ops/deployment/application-requirements/) не виконані.

Наприклад, наступна команда видає попередження, що pod `kube-dns` не є частиною сервісної мережі, оскільки він не має sidecar:

{{< text bash >}}
$ export KUBE_POD=$(kubectl -n kube-system get pod -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod -n kube-system $KUBE_POD
Pod: coredns-f9fd979d6-2zsxk
   Pod Ports: 53/UDP (coredns), 53 (coredns), 9153 (coredns)
WARNING: coredns-f9fd979d6-2zsxk is not part of mesh; no Istio sidecar
--------------------
2021-01-22T16:10:14.080091Z     error   klog    an error occurred forwarding 42785 -> 15000: error forwarding port 15000 to pod 692362a4fe313005439a873a1019a62f52ecd02c3de9a0957cd0af8f947866e5, uid : failed to execute portforward in network namespace "/var/run/netns/cni-3c000d0a-fb1c-d9df-8af8-1403e6803c22": failed to dial 15000: dial tcp4 127.0.0.1:15000: connect: connection refused[]
Error: failed to execute command on sidecar: failure running port forward process: Get "http://localhost:42785/config_dump": EOF
{{< /text >}}

Команда не видасть такого попередження для podʼа, який є частиною mesh, наприклад, для сервісу Bookinfo `ratings`, але натомість виведе конфігурацію Istio, застосовану до podʼа:

{{< text bash >}}
$ export RATINGS_POD=$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')
$ istioctl experimental describe pod $RATINGS_POD
Pod: ratings-v1-7dc98c7588-8jsbw
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP targets pod port 9080
{{< /text >}}

Виведення показує наступну інформацію:

- Порти контейнера сервіса в podʼі, `9080` для контейнера `ratings` у цьому прикладі.
- Порти контейнера `istio-proxy` в podʼі, `15090` у цьому прикладі.
- Протокол, що використовується службою в podʼі, `HTTP` через порт `9080` у цьому прикладі.

## Перевірте конфігурації правил призначення {#verify-destination-rule-configurations}

Ви можете використовувати `istioctl describe`, щоб побачити, які
[правила призначення](/docs/concepts/traffic-management/#destination-rules) застосовуються до запитів до podʼа. Наприклад, застосуйте правила призначення для Bookinfo [з взаємним TLS]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml):

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Тепер опишіть pod `ratings` знову:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pod: ratings-v1-f745cf57b-qrxl2
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP
DestinationRule: ratings for "ratings"
   Matching subsets: v1
      (Non-matching subsets v2,v2-mysql,v2-mysql-vm)
   Traffic Policy TLS Mode: ISTIO_MUTUAL
{{< /text >}}

Команда тепер показує додаткове виведення:

- Правило призначення `ratings` застосовується до запитів до сервісів `ratings`.
- Підмножина правила призначення `ratings`, що відповідає podʼу, `v1` у цьому прикладі.
- Інші підмножини, визначені правилом призначення.
- Pod приймає або HTTP, або взаємні TLS запити, але клієнти використовують взаємний TLS.

## Перевірте конфігурації віртуальних сервісів {#verify-virtual-service-configurations}

Коли [віртуальні сервіси](/docs/concepts/traffic-management/#virtual-services) конфігурують маршрути до podʼа, `istioctl describe` також включатиме маршрути у своєму виведенні. Наприклад, застосуйте [віртуальні сервіси Bookinfo]({{< github_file>}}/samples/bookinfo/networking/virtual-service-all-v1.yaml), які маршрутизують всі запити до podʼів `v1`:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

Потім опишіть pod, що реалізує `v1` сервіси `reviews`:

{{< text bash >}}
$ export REVIEWS_V1_POD=$(kubectl get pod -l app=reviews,version=v1 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   1 HTTP route(s)
{{< /text >}}

Виведення містить подібну інформацію до тієї, що була показана раніше для podʼа `ratings`, але також включає маршрути віртуального сервісу до podʼа.

Команда `istioctl describe` не просто показує віртуальні сервіси, що впливають на pod. Якщо віртуальний сервіс конфігурує хост служби podʼа, але жоден трафік не досягає його, виведення команди міститиме попередження. Цей випадок може виникнути, якщо віртуальний сервіс
фактично блокує трафік, ніколи не маршрутизуючи трафік до підмножини podʼа. Наприклад:

{{< text bash >}}
$ export REVIEWS_V2_POD=$(kubectl get pod -l app=reviews,version=v2 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V2_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Route to non-matching subset v1 for (everything)
{{< /text >}}

Попередження включає причину проблеми, скільки маршрутів було перевірено, і навіть надає інформацію про інші маршрути, що існують. У цьому прикладі жоден трафік не досягає podʼа `v2`, оскільки маршрут у віртуальному сервісі спрямовує весь трафік до підмножини `v1`.

Якщо ви зараз видалите правила призначення Bookinfo:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Ви зможете побачити ще одну корисну функцію `istioctl describe`:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Warning: Route to subset v1 but NO DESTINATION RULE defining subsets!
{{< /text >}}

Виведення показує, що ви видалили правило призначення, але не віртуальний сервіс, що залежить від нього. Віртуальний сервіс маршрутизує трафік до підмножини `v1`, але немає правила призначення, що визначає підмножину `v1`. Таким чином, трафік, призначений для версії `v1`, не може дійти до podʼа.

Якщо ви оновите оглядач, щоб надіслати новий запит до Bookinfo в цей момент, ви побачите таке повідомлення: `Error fetching product reviews`. Щоб виправити проблему, знову застосуйте правило призначення:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Оновлення оглядача показує, що застосунок знову працює, і виконання `istioctl experimental describe pod $REVIEWS_V1_POD` більше не видає  попереджень.

## Перевірка маршрутів трафіку {#verifying-traffic-routes}

Команда `istioctl describe` також показує ваги розподілу трафіку. Наприклад, виконайте наступну команду, щоб маршрутизувати 90% трафіку до підмножини `v1` і 10% до підмножини `v2` сервісу `reviews`:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-90-10.yaml@
{{< /text >}}

Тепер опишіть pod `reviews v1`:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   Weight 90%
{{< /text >}}

Виведення показує, що віртуальний сервіс `reviews` має вагу 90% для
підмножини `v1`.

Ця функція також корисна для інших типів маршрутизації. Наприклад, ви можете розгорнути маршрутизацію на основі заголовків:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
{{< /text >}}

Потім опишіть pod знову:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 2 HTTP routes)
      Route to non-matching subset v2 for (when headers are end-user=jason)
      Route to non-matching subset v3 for (everything)
{{< /text >}}

Виведення видає попередження, оскільки ви описуєте pod у підмножині `v1`. Однак конфігурація віртуального сервісу, яку ви застосували, маршрутизує трафік до підмножини `v2`, якщо заголовок містить `end-user=jason`, і до підмножини `v3` у всіх інших випадках.

## Перевірка строгого взаємного TLS {#verifying-strict-mutual-tls}

Слідуйте інструкціям [міграції взаємного TLS](/docs/tasks/security/authentication/mtls-migration/), щоб увімкнути строгий взаємний TLS для сервісу `ratings`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: ratings-strict
spec:
  selector:
    matchLabels:
      app: ratings
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Виконайте наступну команду, щоб описати pod `ratings`:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pilot reports that pod enforces mTLS and clients speak mTLS
{{< /text >}}

У виводі повідомляється, що запити до пакета `ratings` тепер зафіксовано і захищено.

Однак іноді розгортання може зламатися при переході на строгий взаємний TLS. Ймовірною причиною є те, що правило призначення не відповідало новій конфігурації. Наприклад, якщо ви конфігуруєте клієнтів Bookinfo, щоб не використовувати взаємний TLS, використовуючи [прості правила призначення HTTP]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml):

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

Якщо ви відкриєте Bookinfo в оглядачі, ви побачите повідомлення `Ratings service is currently unavailable`. Щоб дізнатися чому, виконайте наступну команду:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
...
WARNING Pilot predicts TLS Conflict on ratings-v1-f745cf57b-qrxl2 port 9080 (pod enforces mTLS, clients speak HTTP)
  Check DestinationRule ratings/default and AuthenticationPolicy ratings-strict/default
{{< /text >}}

Виведення містить попередження, яке описує конфлікт між правилом призначення та політикою автентифікації.

Ви можете відновити правильну роботу, застосувавши правило призначення, яке використовує взаємний TLS:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

## Висновок та очищення {#conclusion-and-cleanup}

Наша мета з командою `istioctl x describe` — допомогти вам зрозуміти конфігурації трафіку та безпеки у вашій Mesh Istio.

Ми будемо раді почути ваші ідеї щодо покращення! Приєднуйтесь до нас на [https://discuss.istio.io](https://discuss.istio.io).

Щоб видалити podʼи та конфігурації Bookinfo, використані в цьому посібнику, виконайте наступні команди:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl delete -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}
