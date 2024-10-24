---
title: Балансування навантаження за локацією
description: Ця серія завдань демонструє, як налаштувати балансування навантаження за їх місцем знаходження в Istio.
weight: 65
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
list_below: true
simple_list: true
content_above: true
aliases:
  - /uk/help/ops/traffic-management/locality-load-balancing
  - /uk/help/ops/locality-load-balancing
  - /uk/help/tasks/traffic-management/locality-load-balancing
  - /uk/docs/ops/traffic-management/locality-load-balancing
  - /uk/docs/ops/configuration/traffic-management/locality-load-balancing
owner: istio/wg-networking-maintainers
test: n/a
---
*Локація* визначає географічне розташування {{< gloss "Екземпляр робочого навантаження" >}}екземпляра робочого навантаження{{</ gloss >}} у вашій мережі. Наступне тріо визначає локацію:

- **Region**: Представляє велику географічну область, таку як *us-east*. Регіон зазвичай містить кілька зон доступності. У Kubernetes мітка [`topology.kubernetes.io/region`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesioregion) визначає регіон вузла.

- **Zone**: Набір обчислювальних ресурсів у межах регіону. Запуск сервісів у кількох зонах у межах регіону дозволяє здійснювати перехід між зонами в межах регіону, зберігаючи при цьому локальність даних для кінцевого користувача. У Kubernetes мітка [`topology.kubernetes.io/zone`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesiozone) визначає зону вузла.

- **Sub-zone**: Дозволяє адміністраторам далі поділити зони для більш детального контролю, наприклад, "та сама стійка". Концепція суб-зони не існує в Kubernetes. В результаті, Istio ввів власну мітку вузла [`topology.istio.io/subzone`](/docs/reference/config/labels/#:~:text=topology.istio.io/subzone) для визначення суб-зони.

{{< tip >}}
Якщо ви використовуєте хостинг-сервіс Kubernetes, ваш постачальник хмари повинен налаштувати мітки регіону та зони для вас. Якщо ви запускаєте власний кластер Kubernetes, вам потрібно буде додати ці мітки до ваших вузлів.
{{< /tip >}}

Локації є ієрархічними, у відповідному порядку:

1. Регіон

1. Зона

1. Суб-зона

Це означає, що pod, що працює в зоні `bar` регіону `foo`, **не** вважається локальним для podʼа, що працює в зоні `bar` регіону `baz`.

Istio використовує цю інформацію про локацію для контролю поведінки балансування навантаження. Ознайомтесь з одним з завдань у цій серії, щоб налаштувати балансування навантаження за локацією для вашої мережі.
