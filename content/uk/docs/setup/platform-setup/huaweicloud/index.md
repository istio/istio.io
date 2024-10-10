---
title: Huawei Cloud
description: Інструкції для налаштування кластера Huawei Cloud Kubernetes для Istio.
weight: 23
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/huaweicloud/
    - /uk/docs/setup/kubernetes/platform-setup/huaweicloud/
keywords: [platform-setup,huawei,huaweicloud,cce]
owner: istio/wg-environments-maintainers
test: no
---

Дотримуйтесь цих інструкцій, щоб підготувати кластер для Istio за допомогою [Huawei Cloud Container Engine](https://www.huaweicloud.com/intl/product/cce.html). Ви можете швидко і легко розгорнути кластер Kubernetes на Huawei Cloud у `Cloud Container Engine Console`, який повністю підтримує Istio.

{{< tip >}}
Huawei пропонує надбудову {{< gloss "Керована панель управління">}}керованої панелі управління{{< /gloss >}} для Huawei Cloud Container Engine, яку ви можете використовувати замість ручної установки Istio. Деталі та інструкції можна знайти в [Huawei Application Service Mesh](https://support.huaweicloud.com/asm/index.html).
{{< /tip >}}

Дотримуйтесь [інструкцій Huawei Cloud](https://support.huaweicloud.com/en-us/qs-cce/cce_qs_0008.html) для підготовки кластера перед ручною установкою Istio, виконайте наступні кроки:

1. Увійдіть до консолі CCE. Виберіть **Dashboard** > **Buy Cluster**, щоб відкрити сторінку **Buy Hybrid Cluster**. Альтернативний спосіб відкрити цю сторінку — вибрати **Resource Management** > **Clusters** в навігаційній панелі та натиснути **Buy** поруч з **Hybrid Cluster**.

2. На сторінці **Configure Cluster** налаштуйте параметри кластера. В цьому прикладі більшість параметрів залишаються зі стандартними налаштуваннями. Після завершення налаштування кластера натисніть Далі: **Create Node**, щоб перейти на сторінку створення вузлів.

   {{< tip >}}
   Для релізу Istio є певні вимоги до версії Kubernetes, виберіть версію відповідно до [політики підтримки Istio](/docs/releases/supported-releases#support-status-of-istio-releases).
   {{< /tip >}}

   Зображення нижче показує GUI, де ви створюєте та налаштовуєте кластер:

   {{< image link="./create-cluster.png" caption="Налаштування кластера" >}}

3. На сторінці створення вузлів налаштуйте наступні параметри

   {{< tip >}}
   Istio додає деяке додаткове споживання ресурсів, згідно з нашим досвідом, зарезервуйте щонайменше 4 vCPU та 8 GB пам’яті для початку.
   {{< /tip >}}

   Зображення нижче показує GUI, де ви створюєте та налаштовуєте вузол:

   {{< image link="./create-node.png" caption="Налаштування вузла" >}}

4. [Налаштуйте kubectl](https://support.huaweicloud.com/intl/en-us/cce_faq/cce_faq_00041.html)

5. Тепер ви можете встановити Istio в кластер CCE згідно з [інструкцією з установки](/docs/setup/install).

6. Налаштуйте [ELB](https://support.huaweicloud.com/intl/productdesc-elb/en-us_topic_0015479966.html) для відкриття Istio ingress gateway, якщо це потрібно.

   - [Створіть Elastic Load Balancer](https://console.huaweicloud.com/vpc/?region=ap-southeast-1#/elbs/createEnhanceElb)

   - Прив’яжіть ELB екземпляр до сервісу `istio-ingressgateway`

     Встановіть ID екземпляра ELB та `loadBalancerIP` для `istio-ingressgateway`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubernetes.io/elb.class: union
    kubernetes.io/elb.id: 4ee43d2b-cec5-4100-89eb-2f77837daa63 # ELB ID
    kubernetes.io/elb.lb-algorithm: ROUND_ROBIN
  labels:
    app: istio-ingressgateway
    install.operator.istio.io/owning-resource: unknown
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio: ingressgateway
    istio.io/rev: default
    operator.istio.io/component: IngressGateways
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: 1.9.0
    release: istio
  name: istio-ingressgateway
  namespace: istio-system
spec:
  clusterIP: 10.247.7.192
  externalTrafficPolicy: Cluster
  loadBalancerIP: 119.8.36.132     ## ELB EIP
  ports:
  - name: status-port
    nodePort: 32484
    port: 15021
    protocol: TCP
    targetPort: 15021
  - name: http2
    nodePort: 30294
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    nodePort: 31301
    port: 443
    protocol: TCP
    targetPort: 8443
  - name: tcp
    nodePort: 30229
    port: 31400
    protocol: TCP
    targetPort: 31400
  - name: tls
    nodePort: 32028
    port: 15443
    protocol: TCP
    targetPort: 15443
  selector:
    app: istio-ingressgateway
    istio: ingressgateway
  sessionAffinity: None
  type: LoadBalancer
EOF
{{< /text >}}

Почніть працювати з Istio, спробувавши різні [завдання](/docs/tasks).
