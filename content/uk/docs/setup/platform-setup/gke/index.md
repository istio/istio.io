---
title: Google Kubernetes Engine
description: Інструкції для налаштування кластера Google Kubernetes Engine для Istio.
weight: 20
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/gke/
    - /uk/docs/setup/kubernetes/platform-setup/gke/
keywords: [platform-setup,kubernetes,gke,google]
owner: istio/wg-environments-maintainers
test: no
---

Дотримуйтесь цих інструкцій, щоб підготувати кластер GKE для Istio.

1. Створіть новий кластер.

    {{< text bash >}}
    $ export PROJECT_ID=`gcloud config get-value project` && \
      export M_TYPE=n1-standard-2 && \
      export ZONE=us-west2-a && \
      export CLUSTER_NAME=${PROJECT_ID}-${RANDOM} && \
      gcloud services enable container.googleapis.com && \
      gcloud container clusters create $CLUSTER_NAME \
      --cluster-version latest \
      --machine-type=$M_TYPE \
      --num-nodes 4 \
      --zone $ZONE \
      --project $PROJECT_ID
    {{< /text >}}

    {{< tip >}}
    Стандартно для Istio потрібні вузли з більше ніж 1 vCPU. Якщо ви
    встановлюєте з [профілем конфігурації demo](/docs/setup/additional-setup/config-profiles/), ви можете прибрати аргумент `--machine-type`, щоб використовувати менший розмір машини `n1-standard-1`.
    {{< /tip >}}

    {{< warning >}}
    Щоб використовувати функцію Istio CNI на GKE, будь ласка, перевірте [посібник з установки CNI](/docs/setup/additional-setup/cni/#prerequisites) для кроків з налаштування кластера.
    {{< /warning >}}

    {{< warning >}}
    **Для приватних кластерів GKE**

    Автоматично створене правило брандмауера не відкриває порт 15017. Це потрібно для валідаційного вебхука istiod discovery.

    Щоб перевірити це правило брандмауера для доступу до майстра:

    {{< text bash >}}
    $ gcloud compute firewall-rules list --filter="name~gke-${CLUSTER_NAME}-[0-9a-z]*-master"
    {{< /text >}}

    Щоб замінити поточне правило та дозволити доступ до майстра:

    {{< text bash >}}
    $ gcloud compute firewall-rules update <firewall-rule-name> --allow tcp:10250,tcp:443,tcp:15017
    {{< /text >}}

    {{< /warning >}}

1. Отримайте ваші облікові дані для `kubectl`.

    {{< text bash >}}
    $ gcloud container clusters get-credentials $CLUSTER_NAME \
        --zone $ZONE \
        --project $PROJECT_ID
    {{< /text >}}

1. Надайте права адміністратора кластера (admin) поточному користувачеві. Для створення необхідних правил RBAC для Istio поточному користувачеві потрібні права адміністратора.

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}

## Комунікація між кластерами {#multi-cluster-communication}

В деяких випадках необхідно явно створити правило брандмауера для дозволу міжкластерного трафіку.

{{< warning >}}
Наступні інструкції дозволять комунікацію між *усіма* кластерами у вашому проєкті. Налаштуйте команди за потреби.
{{< /warning >}}

1. Зберіть інформацію про мережу ваших кластерів.

    {{< text bash >}}
    $ function join_by { local IFS="$1"; shift; echo "$*"; }
    $ ALL_CLUSTER_CIDRS=$(gcloud --project $PROJECT_ID container clusters list --format='value(clusterIpv4Cidr)' | sort | uniq)
    $ ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}"))
    $ ALL_CLUSTER_NETTAGS=$(gcloud --project $PROJECT_ID compute instances list --format='value(tags.items.[0])' | sort | uniq)
    $ ALL_CLUSTER_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))
    {{< /text >}}

1. Створіть правило брандмауера.

    {{< text bash >}}
    $ gcloud compute firewall-rules create istio-multicluster-pods \
        --allow=tcp,udp,icmp,esp,ah,sctp \
        --direction=INGRESS \
        --priority=900 \
        --source-ranges="${ALL_CLUSTER_CIDRS}" \
        --target-tags="${ALL_CLUSTER_NETTAGS}" --quiet
    {{< /text >}}
