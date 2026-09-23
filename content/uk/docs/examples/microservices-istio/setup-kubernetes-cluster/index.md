---
title: Налаштування кластера Kubernetes
overview: Налаштуйте ваш кластер Kubernetes для посібника.
weight: 2
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

У цьому модулі ви налаштуєте кластер Kubernetes, на якому встановлений Istio, і простір імен для використання протягом ознайомлення з посібником.

{{< warning >}}
Якщо ви на майстер-класі та інструктори надають кластер, перейдіть до [налаштування вашого локального компʼютера](/docs/examples/microservices-istio/setup-local-computer).
{{</ warning >}}

1. Переконайтеся, що у вас є доступ до [кластера Kubernetes](https://kubernetes.io/docs/tutorials/kubernetes-basics/). Ви можете використовувати [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/quickstart) або [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started).

2. Створіть змінну середовища для зберігання назви простору імен, який ви будете використовувати при виконанні команд посібника. Ви можете використовувати будь-яке імʼя, наприклад `tutorial`.

    {{< text bash >}}
    $ export NAMESPACE=tutorial
    {{< /text >}}

3. Створіть простір імен:

    {{< text bash >}}
    $ kubectl create namespace $NAMESPACE
    {{< /text >}}

    {{< tip >}}
    Якщо ви інструктор, вам слід виділити окремий простір імен для кожного учасника. Посібник підтримує роботу в кількох просторах імен одночасно для кількох учасників.
    {{< /tip >}}

4. [Встановіть Istio](/docs/setup/getting-started/) за допомогою профілю `demo`.

5. У цьому прикладі використовуються надбудови [Kiali](/docs/ops/integrations/kiali/) та [Prometheus](/docs/ops/integrations/prometheus/), які потрібно встановити. Усі надбудови встановлюються за допомогою:

    {{< text bash >}}
    $ kubectl apply -f @samples/addons@
    {{< /text >}}

    {{< tip >}}
    Якщо виникають помилки при спробі встановити надбудови, спробуйте знову виконати команду. Можуть бути проблеми з таймінгом, які вирішаться при повторному виконанні команди.
    {{< /tip >}}

6. Створіть ресурс Ingress Kubernetes для цих загальних сервісів Istio за допомогою команди `kubectl`, як показано нижче. На цьому етапі посібника не обовʼязково бути знайомим з кожним з цих сервісів.

   - [Grafana](https://grafana.com/docs/guides/getting_started/)
   - [Jaeger](https://www.jaegertracing.io/docs/1.13/getting-started/)
   - [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
   - [Kiali](https://kiali.io/docs/installation/quick-start/)

   Команда `kubectl` може приймати конфігурацію в рядку для створення ресурсів Ingress для кожного сервісу:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: istio-system
      namespace: istio-system
      annotations:
        kubernetes.io/ingress.class: istio
    spec:
      rules:
      - host: my-istio-dashboard.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
      - host: my-istio-tracing.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tracing
                port:
                  number: 9411
      - host: my-istio-logs-database.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus
                port:
                  number: 9090
      - host: my-kiali.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kiali
                port:
                  number: 20001
    EOF
    {{< /text >}}

1.  Створіть роль для надання доступу на читання до простору імен `istio-system`. Ця роль необхідна для обмеження дозволів учасників в кроках нижче.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-system-access
      namespace: istio-system
    rules:
    - apiGroups: ["", "extensions", "apps"]
      resources: ["*"]
      verbs: ["get", "list"]
    EOF
    {{< /text >}}

1.  Створіть службовий обліковий запис для кожного учасника:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    EOF
    {{< /text >}}

1.  Обмежте дозволи кожного учасника. Під час навчання учасникам треба тільки створювати ресурси у власному просторі імен та читати ресурси з простору імен `istio-system`. Це хороша практика, навіть якщо ви використовуєте власний кластер, уникати втручання в інші простори імен у вашому кластері.

    Створіть роль для надання доступу на читання та запис у простір імен кожного учасника. Прив’яжіть службовий обліковий запис учасника до цієї ролі та до ролі для читання ресурсів з `istio-system`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    rules:
    - apiGroups: ["", "extensions", "apps", "networking.k8s.io", "networking.istio.io", "authentication.istio.io",
                  "rbac.istio.io", "config.istio.io", "security.istio.io"]
      resources: ["*"]
      verbs: ["*"]
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: ${NAMESPACE}-access
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-istio-system-access
      namespace: istio-system
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: istio-system-access
    EOF
    {{< /text >}}

1.  Кожен учасник повинен використовувати свій власний файл конфігурації Kubernetes. Цей файл конфігурації вказує деталі кластера, службовий обліковий запис, облікові дані та простір імен учасника. Команда `kubectl` використовує файл конфігурації для роботи з кластером.

    Згенеруйте файл конфігурації Kubernetes для кожного учасника:

    {{< tip >}}
    Ця команда передбачає, що ваш кластер має назву `tutorial-cluster`. Якщо ваш кластер має іншу назву, замініть усі посилання на назву вашого кластера.
    {{</ tip >}}

    {{< text bash >}}
    $ cat <<EOF > ./${NAMESPACE}-user-config.yaml
    apiVersion: v1
    kind: Config
    preferences: {}

    clusters:
    - cluster:
        certificate-authority-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        server: $(kubectl config view -o jsonpath="{.clusters[?(.name==\"$(kubectl config view -o jsonpath="{.contexts[?(.name==\"$(kubectl config current-context)\")].context.cluster}")\")].cluster.server}")
      name: ${NAMESPACE}-cluster

    users:
    - name: ${NAMESPACE}-user
      user:
        as-user-extra: {}
        client-key-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        token: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath={.data.token} | base64 --decode)

    contexts:
    - context:
        cluster: ${NAMESPACE}-cluster
        namespace: ${NAMESPACE}
        user: ${NAMESPACE}-user
      name: ${NAMESPACE}

    current-context: ${NAMESPACE}
    EOF
    {{< /text >}}

1. Встановіть змінну середовища `KUBECONFIG` для файлу конфігурації `${NAMESPACE}-user-config.yaml`:

    {{< text bash >}}
    $ export KUBECONFIG=$PWD/${NAMESPACE}-user-config.yaml
    {{< /text >}}

1. Перевірте, що конфігурація була застосована, вивівши поточний простір імен:

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    Ви повинні побачити імʼя вашого простору імен у виводі.

1. Якщо ви налаштовуєте кластер для себе, скопіюйте файл `${NAMESPACE}-user-config.yaml`, згаданий у попередніх кроках, на ваш компʼютер, де `${NAMESPACE}` — це імʼя простору імен, яке ви вказали в попередніх кроках. Наприклад, `tutorial-user-config.yaml`. Вам знадобиться цей файл пізніше в навчанні.

    Якщо ви інструктор, надішліть згенеровані файли конфігурації кожному учаснику. Учасники повинні скопіювати свої файли конфігурації на свої компʼютери.

Вітаємо, ви налаштували свій кластер для навчання!

Ви готові [налаштувати локальний компʼютер](/docs/examples/microservices-istio/setup-local-computer).
