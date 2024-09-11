---
title: Екземпляр робочого навантаження
test: n/a
---

Один екземпляр [бінарного файлу навантаження](/docs/reference/glossary/#workload). Екземпляр навантаження може експонувати нуль або більше [точок доступу сервісу](/docs/reference/glossary/#service-endpoint) та може споживати нуль або більше [сервісів](/docs/reference/glossary/#service).

Екземпляри навантаження мають кілька властивостей:

- Назва та простір імен
- Унікальний ID
- IP-адреса
- Мітки
- Принципал

Ці властивості доступні в конфігураціях політики та телеметрії за допомогою багатьох [`source.*` та `destination.*` атрибутів](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).
