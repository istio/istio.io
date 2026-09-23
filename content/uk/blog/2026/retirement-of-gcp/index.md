---
title: "ДІЇ, ЯКІ НЕОБХІДНО ВИКОНАТИ КОРИСТУВАЧАМ GOOGLE CONTAINER REGISTRY, тести «scream» та наш перехід на AWS"
description: Що ви можете зробити зі своїми Helm-чартами та ключами підпису, щоб уникнути негативних наслідків від переходу на AWS.
publishdate: 2026-08-21
attribution: Steven Jin (Microsoft), Keith Mattix (Solo.io)
keywords: [Istio,Container Registry,Helm]
---

Цього року Istio мігрує всю нашу інфраструктуру з Google Cloud Platform до Amazon Web Services через зміни в нашій моделі фінансування. У цьому дописі описується перехід наших контейнерних образів, Helm-чартів, інших артефактів релізу (RPM, DEB, вихідний код, документи SPDX, `istioctl` та ліцензії), ключів підпису та **майбутніх тестів «scream», під час яких ми тимчасово вимкнемо доступ до всіх артефактів, розміщених у GCP**.

## Образи контейнерів {#container-images}

У [попередньому дописі в блозі](/blog/2026/retirement-of-gcr.io-follow-up/) ми оголосили, що реєстри контейнерів `gcr.io/istio-release` та `registry.istio.io` будуть виведені з експлуатації в грудні 2026 року, і ми будемо публікувати образи контейнерів Istio лише на Docker Hub. Починаючи з Istio 1.31, ми будемо публікувати образи контейнерів Istio лише на `docker.io/istio`. Детальніше про міграцію з `gcr.io/istio-release` та `registry.istio.io` див. у [попередньому дописі в блозі](/blog/2026/retirement-of-gcr.io-follow-up/).

## Helm-чарти та інші артефакти релізу {#helm-charts-and-other-release-artifacts}

Історично Istio публікував Helm-чарти на `https://istio-release.storage.googleapis.com/charts`, а також `gcr.io/istio-release/charts` як OCI-артефакти. Подібним чином ми публікували інші артефакти релізу (RPM, DEB, вихідний код, документи SPDX, `istioctl` та ліцензії) на `https://istio-release.storage.googleapis.com/releases`. Helm-чарти та інші артефакти релізу будуть видалені з вищезгаданих місць у грудні 2026 року. Усі Helm-чарти всіх версій Istio наразі доступні на `https://blob.istio.io/istio-release/charts`, і ми продовжимо публікувати їх там у найближчому майбутньому. Усі OCI Helm-чарти всіх версій Istio наразі доступні на `ghcr.io/istio/release/charts`, і ми продовжимо публікувати їх там у найближчому майбутньому. Усі інші артефакти релізу всіх версій Istio наразі доступні на `https://blob.istio.io/istio-release/releases`, і ми продовжимо публікувати їх там у найближчому майбутньому. Istio 1.30 буде останньою мінорною версією з Helm-чартами, OCI Helm-чартами та образами, опублікованими на `gcr.io/istio-release`, `registry.istio.io/release` та `https://istio-release.storage.googleapis.com/charts`. Istio 1.31 **не** матиме Helm-чартів, OCI Helm-чартів, ані образів, опублікованих на `gcr.io/istio-release/`, `registry.istio.io/release` та `https://istio-release.storage.googleapis.com/charts`. Більше інформації буде доступно в нотатках до релізу.

## Ключі підпису {#signing-keys}

Внаслідок нашої міграції ми змінимо наші пари публічних/приватних ключів. Старий публічний ключ ми й надалі розміщуватимемо за адресою `https://istio.io/misc/istio-key.pub`. Проте новіші образи будуть підписані новим ключем, відповідний публічний ключ якого буде доступний за адресою `https://istio.io/misc/istio-key-v2.pub`.

Очікується, що для кожного релізу будуть використовуватися такі ключі підпису:

| Version | Signing Public Key |
| --------- | ------------- |
| 1.18.x - 1.30.x | `https://istio.io/misc/istio-key.pub` |
| 1.31.0 | `https://istio.io/misc/istio-key.pub` |
| 1.31.1+ | `https://istio.io/misc/istio-key-v2.pub` |

## Тести scream та що вам потрібно зробити {#scream-tests-and-what-you-need-to-do}

Ми проведемо серію "scream-тестів", під час яких тимчасово буде відключено доступ до `gcr.io/istio-release`, `registry.istio.io/release` та `https://istio-release.storage.googleapis.com/`. Перший scream-тест відбудеться 15 вересня 2026 року з 15:00 до 16:00 за UTC. Другий scream-тест відбудеться 13 жовтня 2026 року з 15:00 до 18:00 за UTC. Третій scream-тест відбудеться 17 листопада 2026 року з 15:00 до 21:00 за UTC. Четвертий і останній scream-тест відбудеться з 8 грудня 2026 року 15:00 за UTC до 9 грудня 2026 року 15:00 за UTC.

Якщо ви використовуєте `registry.istio.io/release` або `gcr.io/istio-release`, вам слід якомога швидше перейти на `docker.io/istio` або кеш із можливістю pull-through. Якщо ви встановлюєте Istio за допомогою Helm-чартів з `https://istio-release.storage.googleapis.com/charts`, вам слід якомога швидше перейти на `https://blob.istio.io/istio-release/charts`. Якщо ви встановлюєте Istio за допомогою OCI Helm-чартів з `gcr.io/istio-release/charts`, вам слід якомога швидше перейти на `ghcr.io/istio/release/charts`. Якщо ви перевіряєте підпис образів Istio, стежте за тим, який ключ підпису використовується для вашої версії Istio, і відповідно оновлюйте свій публічний ключ. Вам слід завершити міграцію якомога швидше, щоб уникнути будь-яких перебоїв у ваших розгортаннях Istio.
