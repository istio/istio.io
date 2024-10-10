---
title: Tencent Cloud
description: Інструкції для швидкого налаштування Istio в Tencent Cloud.
weight: 65
skip_seealso: true
keywords: [platform-setup,tencent-cloud-mesh,tcm,tencent-cloud,tencentcloud]
owner: istio/wg-environments-maintainers
test: n/a
---

## Попередні умови {#prerequisites}

Виконайте ці інструкції, щоб підготувати кластер [Tencent Kubernetes Engine](https://intl.cloud.tencent.com/products/tke) або [Elastic Kubernetes Service](https://intl.cloud.tencent.com/product/eks) для Istio.

Ви можете розгорнути кластер Kubernetes у Tencent Cloud за допомогою [Tencent Kubernetes Engine](https://intl.cloud.tencent.com/document/product/457/40029) або [Elastic Kubernetes Service](https://intl.cloud.tencent.com/document/product/457/34048), які повністю підтримують Istio.

{{< image link="./tke.png" caption="Створення кластера" >}}

## Процедура {#procedure}

Після створення кластера Tencent Kubernetes Engine або Elastic Kubernetes Service, ви можете швидко почати розгортати та використовувати Istio за допомогою [Tencent Cloud Mesh](https://cloud.tencent.com/product/tcm):

{{< image link="./tcm.png" caption="Створення Tencent Cloud Mesh" >}}

1. Увійдіть до `Container Service console`, і натисніть **Service Mesh** в лівій панелі навігації, щоб перейти на сторінку **Service Mesh**.

2. Натисніть кнопку **Створити** у верхньому лівому куті.

3. Введіть назву mesh.

    {{< tip >}}
    Назва mesh може бути довжиною від 1 до 60 символів та містити цифри, китайські символи, латинські літери та дефіси (-).
    {{< /tip >}}

4. Виберіть **Регіон** та **Зону**, де знаходиться кластер.

5. Виберіть версію Istio.

6. Виберіть режим service mesh: `Managed Mesh` або `Stand-Alone  Mesh`.

    {{< tip >}}
    Tencent Cloud Mesh підтримує **Stand-Alone Mesh** (Istiod працює в кластері користувача та керується користувачами) і **Managed Mesh** (Istiod керується командою Tencent Cloud Mesh).
    {{< /tip >}}

7. Налаштуйте політику трафіку Egress: `Register Only` чи `Allow Any`.

8. Виберіть відповідний кластер **Tencent Kubernetes Engine** або **Elastic Kubernetes Service**.

9. Виберіть для відкриття інʼєкції sidecar у вибраних просторах імен.

10. Налаштуйте зовнішні запити для обходу блоку IP-адрес, які безпосередньо доступні через sidecar, і зовнішній трафік не зможе використовувати функції керування трафіком Istio, спостережуваності тощо.

11. Виберіть, чи відкривати **SideCar Readiness Guarantee**. Якщо вона відкрита, контейнер застосунку буде створено після запуску sidecar.

12. Налаштуйте Ingress Gateway та Egress Gateway.

{{< image link="./tps.png" caption="Налаштування Спостережуваності" >}}

13. Налаштуйте Спостережуваність для Метрик, Трейсів та Логування.

    {{< tip >}}
    Окрім стандартних сервісів Cloud Monitor, ви можете вибрати відкриття розширених зовнішніх сервісів, таких як [Керований сервіс для Prometheus](https://intl.cloud.tencent.com/document/product/457/38824?has_map=1) та [Cloud Log Service](https://intl.cloud.tencent.com/product/cls).
    {{< /tip >}}

Після виконання цих кроків ви можете підтвердити створення Istio і почати використовувати Istio в Tencent Cloud Mesh.
