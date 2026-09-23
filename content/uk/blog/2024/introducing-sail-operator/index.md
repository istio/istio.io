---
title: "Представляємо Sail Operator: новий спосіб керування Istio"
description: Представляємо Sail Operator для керування Istio, проект від організації istio-ecosystem.
publishdate: 2024-08-19
attribution: "Francisco Herrera — Red Hat"
keywords: [istio,operator,sail,incluster,deprecation]
---

З нещодавнім оголошенням про [застарівання](/blog/2024/in-cluster-operator-deprecation-announcement/) In-Cluster IstioOperator в Istio 1.23 та його подальше видалення в Istio 1.24, ми хочемо підвищити обізнаність про [новий оператор](https://github.com/istio-ecosystem/sail-operator), який команда Red Hat розробляє для керування Istio в рамках організації [istio-ecosystem](https://github.com/istio-ecosystem).

Sail Operator керує життєвим циклом панелей управління Istio, що спрощує й робить ефективнішим процес розгортання, налаштування та оновлення Istio для адміністраторів кластерів у великих виробничих середовищах. Замість того, щоб створювати нову схему конфігурації та "вигадувати велосипед", API Sail Operator побудовані навколо API Helm charts Istio. Усі параметри інсталяції та конфігурації, які надаються через Helm charts Istio, доступні через поля значень CRD Sail Operator. Це означає, що ви можете легко керувати та налаштовувати Istio за допомогою знайомих конфігурацій без необхідності вивчати додаткові елементи.

Sail Operator має три основні концепції ресурсів:

* [Istio](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istio-resource): використовується для керування панелями управління Istio.
* [Istio Revision](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiorevision-resource): представляє ревізію панелі управління, що є інстанцією Istio з певною версією та імʼям ревізії.
* [Istio CNI](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiocni-resource): використовується для керування ресурсами та життєвим циклом втулка Istio CNI. Для інсталяції втулка Istio CNI створюється ресурс `IstioCNI`.

Наразі основна функція Sail Operator — це стратегія оновлення. Оператор надає інтерфейс для керування оновленням панелей управління Istio. Він підтримує дві стратегії оновлення:

* [In Place](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#inplace): зі стратегією `InPlace`, наявна панель управління Istio замінюється новою версією, і sidecarʼи навантажень одразу підключаються до нової панелі управління. Це означає, що навантаження не потрібно переносити з однієї панелі управління на іншу.
* [Revision Based](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#revisionbased): зі стратегією `RevisionBased`, новий екземпляр панелі управління Istio створюється для кожної зміни поля `Istio.spec.version`. Стара панель управління залишається на місці, доки всі навантаження не будуть перенесені на новий екземпляр. Додатково, прапорець `updateWorkloads` може бути встановлений для автоматичного переміщення навантажень на нову панель управління після її готовності.

Ми розуміємо, що оновлення панелі управління Istio повʼязане з ризиками та може вимагати значних зусиль для великих розгортань, тому це є нашим основним фокусом на цей момент. У майбутньому ми розглядаємо можливості покращення Sail Operator для підтримки таких випадків використання, як мультиоренда та ізоляція, федерація між кластерами та спрощена інтеграція зі сторонніми проєктами.

Проєкт Sail Operator ще на стадії alpha і знаходиться у стадії активної розробки. Зазначимо, що як проєкт з організації istio-ecosystem, він не підтримується в рамках основного проєкту Istio. Ми активно шукаємо відгуки та внески від спільноти. Якщо ви бажаєте взяти участь у проєкті, зверніться до [документації](https://github.com/istio-ecosystem/sail-operator/blob/main/README.md) та [інструкцій для внесків](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md). Також ви можете випробувати новий оператор, дотримуючись вказівок у [документації для користувачів](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md).

Для додаткової інформації звʼяжіться з нами:

* [Обговорення](https://github.com/istio-ecosystem/sail-operator/discussions)
* [Питання](https://github.com/istio-ecosystem/sail-operator/issues)
* [Slack](https://istio.slack.com/archives/C06SE9XCK3Q)
