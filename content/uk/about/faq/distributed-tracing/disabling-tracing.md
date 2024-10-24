---
title: Як вимкнути трейсинг?
weight: 50
---

Якщо ви вже встановили Istio з увімкненим трейсингом, ви можете вимкнути його наступним чином:

{{< text plain >}}
# Заповніть <istio namespace> простором імен вашої mesh Istio. Наприклад: istio-system
TRACING_POD=`kubectl get po -n <istio namespace> | grep istio-tracing | awk '{print $1}'`
$ kubectl delete pod $TRACING_POD -n <istio namespace>
$ kubectl delete services tracing zipkin -n <istio namespace>
# Тепер вручну видаліть всі екземпляри trace_zipkin_url з файлу та збережіть його.
{{< /text >}}

Потім дотримуйтесь кроків [розділу очищення завдання Розподілений трейсинг](/docs/tasks/observability/distributed-tracing/zipkin/#cleanup).

Якщо вам взагалі не потрібна функціональність трейсинг, тоді [вимкніть трейсинг](/docs/tasks/observability/distributed-tracing/zipkin/#before-you-begin) під час встановлення Istio.
