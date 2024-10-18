---
title: Реєстр сервісів
test: n/a
---

Istio підтримує внутрішній реєстр сервісів, що містить набір [сервісів](/docs/reference/glossary/#service) та їх відповідні [точки доступу](/docs/reference/glossary/#service-endpoint), які працюють у сервісній мережі. Istio використовує реєстр сервісів для генерації конфігурації [Envoy](/docs/reference/glossary/#envoy).

Istio не забезпечує [виявлення сервісів](https://en.wikipedia.org/wiki/Service_discovery), хоча більшість сервісів автоматично додаються до реєстру за допомогою адаптерів [Pilot](/docs/reference/glossary/#pilot), які відображають виявлені сервіси основної платформи (Kubernetes, Consul, простий DNS). Додаткові сервіси також можуть бути зареєстровані вручну за допомогою конфігурації [`ServiceEntry`](/docs/concepts/traffic-management/#service-entries).
