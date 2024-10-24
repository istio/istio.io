---
title: Alibaba Cloud
description: Інструкції для налаштування Kubernetes кластера Alibaba Cloud для Istio.
weight: 5
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/alicloud/
    - /uk/docs/setup/kubernetes/platform-setup/alicloud/
keywords: [platform-setup,alibaba-cloud,aliyun,alicloud]
owner: istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate untested-document >}}

Слідуйте цим інструкціям для підготовки кластера [Alibaba Cloud Kubernetes Container Service](https://www.alibabacloud.com/product/kubernetes) для роботи з Istio. Ви можете швидко та легко розгорнути Kubernetes кластер на Alibaba Cloud через `Container Service console`, яка повністю підтримує Istio.

{{< tip >}}
Alibaba Cloud пропонує повністю керовану платформу сервісної мережі з назвою Alibaba Cloud Service Mesh (ASM), яка повністю сумісна з Istio. Ознайомтеся з [Alibaba Cloud Service Mesh](https://www.alibabacloud.com/help/doc-detail/147513.htm) для деталей і інструкцій.
{{< /tip >}}

## Передумови {#prerequisites}

1. [Слідуйте інструкціям Alibaba Cloud](https://www.alibabacloud.com/help/doc-detail/95108.htm) для активації наступних сервісів: Container Service, Resource Orchestration Service (ROS) та RAM.

## Процедура {#procedure}

1. Увійдіть до консолі `Container Service`, і натисніть **Clusters** під **Kubernetes** в лівій панелі навігації, щоб перейти на сторінку **Cluster List**.

1. Натисніть кнопку **Create Kubernetes Cluster** у верхньому правому куті.

1. Введіть імʼя кластера. Імʼя кластера може бути від 1 до 63 символів і може містити цифри, китайські ієрогліфи, англійські літери та дефіси (-).

1. Виберіть **регіон** і **зону**, в якій знаходиться кластер.

1. Встановіть тип мережі кластера. Кластери Kubernetes наразі підтримують лише тип мережі VPC.

1. Налаштуйте типи вузлів. Підтримуються типи Pay-As-You-Go та Subscription.

1. Налаштуйте майстер-вузли. Виберіть покоління, сімейство та тип для майстер-вузлів.

1. Налаштуйте робочі вузли. Виберіть, чи потрібно створити робочий вузол або додати наявний ECS екземпляр як робочий вузол.

1. Налаштуйте режим входу та налаштуйте Pod Network CIDR та Service CIDR.
