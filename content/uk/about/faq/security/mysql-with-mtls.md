---
title: Усунення проблем з підключенням до MySQL
description: Усунення проблем з підключенням до MySQL через режим PERMISSIVE.
weight: 95
keywords: [mysql,mtls]
---

Ви можете зіткнутися з тим, що MySQL не може підключитися після встановлення Istio. Це відбувається через те, що MySQL використовує протокол [server first](/docs/ops/deployment/application-requirements/#server-first-protocols), який може заважати виявленню протоколу Istio. Зокрема, використання режиму `PERMISSIVE` для mTLS може спричиняти проблеми. Ви можете побачити повідомлення про помилки, такі як `ERROR 2013 (HY000): Lost connection to MySQL server at 'reading initial communication packet', system error: 0`.

Цю проблему можна вирішити, увімкнувши режим `STRICT` або `DISABLE`, або ж налаштувавши всіх клієнтів на надсилання mTLS. Дивіться більше інформації в розділі [server first protocols](/docs/ops/deployment/application-requirements/#server-first-protocols).
