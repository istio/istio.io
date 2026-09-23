---
title: Моніторинг з Istio
overview: Збір і обрбка метрик сервісної мережі.
weight: 72
owner: istio/wg-docs-maintainers
test: no
---

Моніторинг є критично важливим для підтримки переходу на архітектуру мікросервісів.

З Istio ви отримуєте моніторинг трафіку між мікросервісами з коробки. Ви можете використовувати панель управління Istio для моніторингу ваших мікросервісів в реальному часі.

Istio інтегровано з [Prometheus системою бази даних і моніторингу часових рядів](https://prometheus.io). Prometheus збирає різні метрики, повʼязані з трафіком, і надає [зручну мову запитів](https://prometheus.io/docs/prometheus/latest/querying/basics/) для них.

Нижче наведені кілька прикладів запитів Prometheus, повʼязаних з Istio.

1.  Доступ до інтерфейсу користувача Prometheus за адресою [http://my-istio-logs-database.io](http://my-istio-logs-database.io). (URL `my-istio-logs-database.io` має бути у вашому файлі /etc/hosts, який ви налаштували [раніше](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)).

    {{< image width="80%" link="prometheus.png" caption="Інтерфейс запитів Prometheus" >}}

1.  Виконайте наступні приклади запитів у полі _Expression_. Натисніть кнопку _Execute_, щоб побачити результати запитів у вкладці _Console_. Запити використовують `tutorial` як імʼя простору імен вашого застосунку, замініть його на імʼя вашого простору імен. Для найкращих результатів запустіть симулятор трафіку в реальному часі, описаний у попередніх кроках, при запиті даних.

    1. Отримати всі запити у вашому просторі імен:

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination"}
        {{< /text >}}

    1.  Отримати суму всіх запитів у вашому просторі імен:

        {{< text plain >}}
        sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination"})
        {{< /text >}}

    1.  Отримати запити до мікросервісу `reviews`:

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}
        {{< /text >}}

    1.  [Швидкість](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate) запитів за останні 5 хвилин до всіх інстанцій мікросервісу `reviews`:

        {{< text plain >}}
        rate(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}[5m])
        {{< /text >}}

Запити вище використовують метрику `istio_requests_total`, яка є стандартною метрикою Istio. Ви можете спостерігати інші метрики, зокрема метрики Envoy ([Envoy](https://www.envoyproxy.io) є проксі-сервером Istio). Ви можете побачити зібрані метрики у меню _insert metric at cursor_.

## Наступні кроки {#next-steps}

Вітаємо з завершенням навчального посібника!

Ці завдання є чудовим місцем для початківців, щоб далі оцінити функції Istio, використовуючи цю `demo` установку:

- [Маршрутизація запитів](/docs/tasks/traffic-management/request-routing/)
- [Інʼєкція збоїв](/docs/tasks/traffic-management/fault-injection/)
- [Перемикання трафіку](/docs/tasks/traffic-management/traffic-shifting/)
- [Отримання метрик](/docs/tasks/observability/metrics/querying-metrics/)
- [Візуалізація метрик](/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control/)
- [Візуалізація вашої мережі](/docs/tasks/observability/kiali/)

Перед тим як налаштувати Istio для промислового використання, ознайомтеся з цими ресурсами:

- [Моделі розгортання](/docs/ops/deployment/deployment-models/)
- [Найкращі практики розгортання](/docs/ops/best-practices/deployment/)
- [Вимоги до Podʼів](/docs/ops/deployment/application-requirements/)
- [Загальні інструкції з встановлення](/docs/setup/)

## Приєднуйтесь до спільноти Istio {#join-the-istio-community}

Ми запрошуємо вас ставити питання і давати нам відгуки, приєднавшись до [спільноти Istio](/get-involved/).
