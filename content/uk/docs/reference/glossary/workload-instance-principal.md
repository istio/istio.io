---
title: Workload Instance Principal
test: n/a
---

Перевірений авторитет під яким працює [екземпляр робочого навантаження](/docs/reference/glossary/#workload-instance). Автентифікація сервіс-сервіс в Istio використовується для створення принципала навантаження. Стандартно принципали навантаження відповідають формату SPIFFE ID.

Принципали навантаження доступні в конфігураціях політики та телеметрії за допомогою атрибутів `source.principal` та `destination.principal` [атрибутів](/docs/reference/glossary/#attribute).
