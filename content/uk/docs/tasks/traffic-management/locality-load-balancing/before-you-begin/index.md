---
title: Перш ніж розпочати
description: Початкові кроки перед налаштуванням балансування навантаження за локалізацією.
weight: 1
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---

Перед тим як розпочати завдання з балансування навантаження по локаціях, спочатку необхідно [встановити Istio на кількох кластерах](/docs/setup/install/multicluster). Кластери повинні охоплювати три регіони, що містять чотири зони доступності. Кількість необхідних кластерів може змінюватися залежно від можливостей, які пропонує ваш постачальник хмари.

{{< tip >}}
Для спрощення, ми припустимо, що в мережі є тільки один {{< gloss "основний кластер" >}}primary кластер{{< /gloss >}}. Це спрощує процес налаштування панелі управління, оскільки зміни потрібно застосувати лише до одного кластеру.
{{< /tip >}}

Ми розгорнемо кілька екземплярів застосунку `HelloWorld` наступним чином:

{{< image width="75%"
    link="setup.svg"
    caption="Налаштування для завдань балансування навантаження по локаціях"
    >}}

{{< tip >}}
У середовищі з одним кластером з кількома зонами балансування навантаження по локаціях також можна налаштувати аварійне перемикання на іншу зону в межах того ж кластера. Щоб перевірити це, вам потрібно створити кластер з кількома зонами робочих вузлів і розгорнути екземпляр istiod та додачу в кожній зоні.

1: Якщо у вас немає кластера Kubernetes з кількома зонами, ви можете розгорнути його локально за допомогою `kind` за допомогою наступної команди:

{{< text syntax=bash snip_id=none >}}
$ kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF
{{< /text >}}

2: Використовуйте `topology.kubernetes.io/zone` для маркування кожного робочого вузла назвою зони:

{{< text syntax=bash snip_id=none >}}
$ kubectl label node kind-worker topology.kubernetes.io/zone=us-south10
$ kubectl label node kind-worker2 topology.kubernetes.io/zone=us-south12
$ kubectl label node kind-worker3 topology.kubernetes.io/zone=us-south13
{{< /text >}}

3: Розгорніть istiod на вузлі панелі управління та додачу до helloworld на кожному з робочих вузлів.

{{< /tip >}}

## Змінні оточення {#environment-variables}

Цей посібник передбачає, що всі кластери будуть доступні через контексти у стандартному [файлі конфігурації Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/). Для різних контекстів будуть використовуватися наступні змінні середовища:

Змінна | Опис
-------- | -----------
`CTX_PRIMARY` | Контекст, який використовується для застосування конфігурації до основного кластера.
`CTX_R1_Z1` | Контекст, який використовується для взаємодії з podʼами в `region1.zone1`.
`CTX_R1_Z2` | Контекст, який використовується для взаємодії з podʼами в `region1.zone2`.
`CTX_R2_Z3` | Контекст, який використовується для взаємодії з podʼами в `region2.zone3`.
`CTX_R3_Z4` | Контекст, який використовується для взаємодії з podʼами в `region3.zone4`.

## Створення простору імен `sample` {#create-the-sample-namespace}

Для початку створіть YAML для простору імен `sample` з увімкненим автоматичним додаванням sidecar:

{{< text bash >}}
$ cat <<EOF > sample.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sample
  labels:
    istio-injection: enabled
EOF
{{< /text >}}

Додайте простір імен `sample` до кожного кластера:

{{< text bash >}}
$ for CTX in "$CTX_PRIMARY" "$CTX_R1_Z1" "$CTX_R1_Z2" "$CTX_R2_Z3" "$CTX_R3_Z4"; \
  do \
    kubectl --context="$CTX" apply -f sample.yaml; \
  done
{{< /text >}}

## Розгортання `HelloWorld` {#deploy-helloworld}

Створіть YAML для `HelloWorld` для кожної локації, використовуючи локацію як рядок версії:

{{< text bash >}}
$ for LOC in "region1.zone1" "region1.zone2" "region2.zone3" "region3.zone4"; \
  do \
    ./@samples/helloworld/gen-helloworld.sh@ \
      --version "$LOC" > "helloworld-${LOC}.yaml"; \
  done
{{< /text >}}

Застосуйте YAML `HelloWorld` до відповідного кластера для кожної локації:

{{< text bash >}}
$ kubectl apply --context="${CTX_R1_Z1}" -n sample \
  -f helloworld-region1.zone1.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl apply --context="${CTX_R1_Z2}" -n sample \
  -f helloworld-region1.zone2.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl apply --context="${CTX_R2_Z3}" -n sample \
  -f helloworld-region2.zone3.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl apply --context="${CTX_R3_Z4}" -n sample \
  -f helloworld-region3.zone4.yaml
{{< /text >}}

## Розгортання `Sleep` {#deploy-sleep}

Розгорніть застосунок `Sleep` в `region1` `zone1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_R1_Z1}" \
  -f @samples/sleep/sleep.yaml@ -n sample
{{< /text >}}

## Зачекайте на podʼи `HelloWorld` {#wait-for-helloworld-pods}

Зачекайте, поки podʼи `HelloWorld` в кожній зоні будуть у стані `Running`:

{{< text bash >}}
$ kubectl get pod --context="${CTX_R1_Z1}" -n sample -l app="helloworld" \
  -l version="region1.zone1"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region1.zone1-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

{{< text bash >}}
$ kubectl get pod --context="${CTX_R1_Z2}" -n sample -l app="helloworld" \
  -l version="region1.zone2"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region1.zone2-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

{{< text bash >}}
$ kubectl get pod --context="${CTX_R2_Z3}" -n sample -l app="helloworld" \
  -l version="region2.zone3"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region2.zone3-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

{{< text bash >}}
$ kubectl get pod --context="${CTX_R3_Z4}" -n sample -l app="helloworld" \
  -l version="region3.zone4"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region3.zone4-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

**Вітаємо!** Ви успішно налаштували систему і тепер готові розпочати завдання з балансування навантаження по локаціях!

## Наступні кроки {#next-steps}

Тепер ви можете налаштувати один з наступних варіантів балансування навантаження:

- [Аварійне перемикання по локаціях](/docs/tasks/traffic-management/locality-load-balancing/failover)

- [Розподілення по локаціях за коефіцієнтами](/docs/tasks/traffic-management/locality-load-balancing/distribute)

{{< warning >}}
Необхідно налаштувати тільки один з варіантів балансування навантаження, оскільки вони є взаємозаперечними. Спроба налаштувати обидва може призвести до непередбачуваної поведінки.
{{< /warning >}}
