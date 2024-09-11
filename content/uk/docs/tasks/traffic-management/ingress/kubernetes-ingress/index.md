---
title: Kubernetes Ingress
description: Описує, як налаштувати об'єкт Kubernetes Ingress для експонування сервісу за межами сервісної мережі.
weight: 40
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

Це завдання описує, як налаштувати Istio для експонування сервісу за межі кластера сервісної мережі, використовуючи [Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/).

{{< tip >}}
Рекомендується використовувати [Gateway](/docs/tasks/traffic-management/ingress/ingress-control/), а не Ingress, щоб скористатися повним набором функцій, які пропонує Istio, такими як розширене управління трафіком і функції безпеки.
{{< /tip >}}

## Перш ніж почати  {#before-you-begin}

Дотримуйтесь інструкцій у розділах [Перед початком роботи](/docs/tasks/traffic-management/ingress/ingress-control/#before-you-begin) та [Визначення вхідного IP та портів](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) з [завдання Ingress Gateways](/docs/tasks/traffic-management/ingress/ingress-control/).

## Налаштування доступу через Ingress ресурс {#configuring-ingress-using-an-ingress-resource}

[Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) дозволяє експонувати HTTP та HTTPS маршрути ззовні кластера до сервісів всередині кластеру.

Подивімось, як можна налаштувати `Ingress` на порту 80 для HTTP-трафіку.

1.  Створіть ресурс `Ingress`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      annotations:
        kubernetes.io/ingress.class: istio
      name: ingress
    spec:
      rules:
      - host: httpbin.example.com
        http:
          paths:
          - path: /status
            pathType: Prefix
            backend:
              service:
                name: httpbin
                port:
                  number: 8000
    EOF
    {{< /text >}}

    Анотація `kubernetes.io/ingress.class` необхідна для того, щоб вказати контролеру шлюзу Istio, що він повинен обробляти цей `Ingress`, інакше він буде проігнорований.

1.  Зверніться до сервісу _httpbin_ за допомогою _url_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    Зверніть увагу, що ви використовуєте прапорець `-H`, щоб встановити HTTP-заголовок _Host_ на "httpbin.example.com". Це необхідно, оскільки `Ingress` налаштовано на обробку "httpbin.example.com", але у вашому тестовому середовищі ви не маєте привʼязки DNS для цього хосту і просто надсилаєте запит на IP-адресу входу.

1.  Перейдіть за будь-якою іншою URL-адресою, яка не була відкрита явно. Ви побачите помилку HTTP 404:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## Наступні кроки {#next-steps}

### TLS

`Ingress` підтримує [налаштування TLS](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). Це підтримується Istio, але вказаний `Secret` повинен існувати в просторі імен розгортання `istio-ingressgateway` (зазвичай `istio-system`). Для генерації цих сертифікатів можна використовувати [cert-manager](/docs/ops/integrations/certmanager/).

### Налаштування типу шляху {#specifying-path-type}

Стандартно Istio обробляє шляхи як точні збіги, якщо вони не закінчуються на `/*` або `.*`, в такому випадку вони стають префіксними збігами. Інші регулярні вирази не підтримуються.

У Kubernetes 1.18 було додане нове поле `pathType`. Це дозволяє явно вказувати шлях як `Exact` або `Prefix`.

### Налаштування `IngressClass` {#specifying-ingressclass}

У Kubernetes 1.18 був доданий новий ресурс `IngressClass`, який замінює анотацію `kubernetes.io/ingress.class` на ресурсі `Ingress`. Якщо ви використовуєте цей ресурс, вам потрібно встановити поле `controller` в `istio.io/ingress-controller`. Наприклад:

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: istio
spec:
  controller: istio.io/ingress-controller
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
spec:
  ingressClassName: istio
  rules:
  - host: httpbin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 8000
{{< /text >}}

## Очищення {#cleanup}

Видаліть конфігурацію `Ingress` і вимкніть службу [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete ingress ingress
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
