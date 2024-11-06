---
title: Оновлення за допомогою Helm
description: Модернізація встановлення в режимі оточення за допомогою Helm.
weight: 5
aliases:
  - /uk/docs/ops/ambient/upgrade/helm-upgrade
  - /uk/latest/docs/ops/ambient/upgrade/helm-upgrade
  - /uk/docs/ambient/upgrade/helm
  - /uk/latest/docs/ambient/upgrade/helm
owner: istio/wg-environments-maintainers
test: yes
---

Скористайтесь цим посібником для оновлення та налаштування установки в режимі ambient, використовуючи [Helm](https://helm.sh/docs/). Цей посібник передбачає, що ви вже виконали [установку в режимі ambient за допомогою Helm](/docs/ambient/install/helm/) з попередньою версією Istio.

{{< warning >}}
На відміну від режиму sidecar, режим ambient підтримує переміщення podʼів застосунку на оновлений проксі ztunnel без обовʼязкового перезапуску або переспрямування працюючих podʼів застосунку. Однак, оновлення ztunnel **призведе** до скидання всіх довготривалих TCP-зʼєднань на оновленому вузлі, і Istio наразі не підтримує канаркове оновлення ztunnel, **навіть з використанням ревізій**.

Рекомендується використовувати ізоляцію вузлів та сині/зелені пули вузлів, щоб обмежити обсяг збою трафіку під час оновлень встановлень в операційному оточенні. Детальніше дивіться у документації вашого провайдера Kubernetes.
{{< /warning >}}

## Розуміння оновлень у режимі ambient {#understanding-ambient-mode-upgrades}

Усі оновлення Istio передбачають оновлення панелі управління, панелі даних та CRD Istio. Оскільки панель даних у режимі ambient розділена між [двома компонентами](/docs/ambient/architecture/data-plane), ztunnel та шлюзів (які включають waypoint), оновлення включають окремі кроки для цих компонентів. Оновлення панелі управління та CRD розглянуті тут коротко, але по суті є аналогічними [процесу оновлення цих компонентів у режимі sidecar](/docs/setup/upgrade/canary/).

Як і в режимі sidecar, шлюзи можуть використовувати [теґи ревізій](/docs/setup/upgrade/canary/#stable-revision-labels) для тонкого контролю за оновленнями ({{< gloss gateway>}}шлюзів{{</ gloss >}}), включаючи waypoint, з простими контролерами для відкочування до попередньої версії панелі правління Istio в будь-який момент. Однак, на відміну від режиму sidecar, ztunnel працює як DaemonSet, проксі на кожному вузлі, — це означає, що оновлення ztunnel мінімум вплине на весь вузол одночасно. Хоча це може бути прийнятним у багатьох випадках, застосунки з довготривалими TCP-зʼєднаннями можуть бути порушені. У таких випадках ми рекомендуємо використовувати ізоляцію вузлів і очищення перед оновленням ztunnel для конкретного вузла. Заради простоти цей документ продемонструє оновлення ztunnel на місці, що може спричинити короткочасний простій.

## Попередні вимоги {#prerequisites}

### Підготовка до оновлення {#prepare-for-the-upgrade}

Перед оновленням Istio ми рекомендуємо завантажити нову версію istioctl та запустити `istioctl x precheck`, щоб переконатися, що оновлення сумісне з вашим середовищем. Результат має виглядати приблизно так:

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

Тепер оновіть репозиторій Helm:

{{< text syntax=bash snip_id=update_helm >}}
$ helm repo update istio
{{< /text >}}

{{< tabset category-name="upgrade-prerequisites" >}}

{{< tab name="Оновлення на місці" category-value="in-place" >}}

Без додаткової підготовки до оновлення на місці, переходьте до наступного кроку.

{{< /tab >}}

{{< tab name="Оновлення з ревізією" category-value="revisions" >}}

### Організуйте свої теґи та ревізії {#organize-your-tags-and-revisions}

Для безпечного оновлення mesh у режимі ambient ваші шлюзи та простори імен повинні використовувати мітку `istio.io/rev` для вказання теґу ревізії, який контролює версію проксі, що виконується. Ми рекомендуємо розділити ваш операційний кластер на кілька теґів для організації вашого оновлення. Усі учасники одного теґу будуть оновлюватись одночасно, тому розумно розпочинати оновлення з найбільш низькоризикових застосунків. Ми не рекомендуємо використовувати ревізії безпосередньо через мітки для оновлень, оскільки цей процес може легко призвести до випадкового оновлення великої кількості проксі і його складно сегментувати. Щоб побачити, які теґи та ревізії ви використовуєте у вашому кластері, дивіться розділ про оновлення теґів.

### Виберіть ім'я ревізії {#choose-a-revision-name}

Ревізії визначають унікальні екземпляри панелі управління Istio, дозволяючи запускати кілька окремих версій панелі управління одночасно в одному mesh.

Рекомендується, щоб ревізії залишалися незмінними, тобто після встановлення панелі управління з певною назвою ревізії встановлення не слід змінювати, а назву ревізії не слід повторно використовувати. Теґи, з іншого боку, є змінними покажчиками на ревізії. Це дозволяє оператору кластера виконувати оновлення панелі даних без необхідності змінювати будь-які мітки робочих навантажень, просто переміщуючи теґ з однієї ревізії на іншу. Всі панелі даних будуть підключатися лише до однієї панелі управління, вказану міткою `istio.io/rev` (яка вказує або на ревізію, або на теґ), або стандартно, якщо мітка `istio.io/rev` відсутня. Оновлення панелі даних складається з простої зміни панелі управління, на яку вона вказує, за допомогою модифікації міток або редагування теґів.

Оскільки ревізії призначені залишатися незмінними, ми рекомендуємо вибрати назву ревізії, яка відповідає версії Istio, яку ви встановлюєте, наприклад `1-22-1`. Окрім вибору нової назви ревізії, вам слід зазначити свою поточну назву ревізії. Ви можете знайти її, виконавши:

{{< text syntax=bash snip_id=list_revisions >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/rev,!istio.io/tag' -L istio\.io/rev
$ # Збережіть вашу ревізію та нову ревізію у змінних:
$ export REVISION=istio-1-22-1
$ export OLD_REVISION=istio-1-21-2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Оновлення панелі управління {#upgrade-the-control-plane}

### Основні компоненти {#base-components}

{{< boilerplate crd-upgrade-123 >}}

Перш ніж розгортати нову версію панелі управління, необхідно оновити CRD, що охоплюють весь кластер:

{{< text syntax=bash snip_id=upgrade_crds >}}
$ helm upgrade istio-base istio/base -n istio-system
{{< /text >}}

### Панель управління istiod {#istiod-control-plane}

Панель управління [Istiod](/docs/ops/deployment/architecture/#istiod) керує і налаштовує проксі, які маршрутизують трафік в межах mesh. Наступна команда встановить новий екземпляр панелі управління поряд з поточним, але не додасть нових шлюзів проксі або waypoints та не візьме на себе керування наявними проксі.

Якщо ви налаштували встановлення istiod, ви можете повторно використовувати файл `values.yaml` з попередніх оновлень або встановлень, щоб зберегти панелі управління узгодженими.

{{< tabset category-name="upgrade-control-plane" >}}

{{< tab name="Оновлення на місці" category-value="in-place" >}}

{{< text syntax=bash snip_id=upgrade_istiod_inplace >}}
$ helm upgrade istiod istio/istiod -n istio-system --wait
{{< /text >}}

{{< /tab >}}

{{< tab name="Оновлення з ревізією" category-value="revisions" >}}

{{< text syntax=bash snip_id=upgrade_istiod_revisioned >}}
$ helm install istiod-"$REVISION" istio/istiod -n istio-system --set revision="$REVISION" --set profile=ambient --wait
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### CNI node agent {#cni-node-agent}

Агент вузла Istio CNI відповідає за виявлення podʼів, доданих до ambient mesh, інформування ztunnel про необхідність встановлення проксі-портів у доданих podʼах і налаштування перенаправлення трафіку в межах мережевого простору імен podʼа. Він не є частиною панелі даних або панелі управління.

CNI версії 1.x сумісний із панеллю управління версії 1.x+1 і 1.x. Це означає, що спочатку потрібно оновити панелі управління перед оновленням Istio CNI, якщо різниця між їхніми версіями не перевищує одну мінорну версію.

{{< warning >}}
Istio зараз не підтримує канаркове оновлення istio-cni, **навіть з використанням ревізій**

Оновлення агента вузла Istio CNI до сумісної версії на місці не призведе до порушення роботи мережі для вже успішно доданих до ambient мережі podʼів, але не слід планувати додавання нових podʼів на вузол, поки оновлення не буде завершено та оновлений агент Istio CNI на вузлі не пройде перевірку готовності. Якщо це може спричинити значні перебої, або якщо потрібен суворіший контроль над зоною впливу під час оновлення CNI, рекомендується застосувати taints вузла та/або cordons вузла.
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_cni >}}
$ helm upgrade istio-cni istio/cni -n istio-system
{{< /text >}}

## Оновлення панелі даних {#upgrade-the-data-plane}

### Ztunnel DaemonSet {#ztunnel-daemonset}

{{< gloss >}}Ztunnel{{< /gloss >}} DaemonSet є проксі-компонентом вузла. Ztunnel версії 1.x сумісний з панеллю управління версії 1.x+1 і 1.x. Це означає, що спочатку потрібно оновити панель управління перед оновленням ztunnel, якщо різниця між їхніми версіями не перевищує одну мінорну версію. Якщо ви раніше налаштовували встановлення ztunnel, ви можете повторно використати файл `values.yaml` з попередніх оновлень або встановлень, щоб зберегти ваші {{< gloss "панель даних" >}}панелі даних{{< /gloss >}} послідовним.

{{< warning >}}
Оновлення ztunnel на місці короткочасно порушить весь трафік ambient mesh на вузлі, **навіть з від використанням ревізій**. На практиці період порушення дуже короткий і в основному впливає на довготривалі зʼєднання.

Для зниження ризику зони впливу під час оновлень в операційних середовищах рекомендується використання cordoning вузлів і блакитно-зелених пулів вузлів. Дивіться документацію вашого постачальника Kubernetes для деталей.
{{< /warning >}}

{{< tabset category-name="upgrade-ztunnel" >}}

{{< tab name="Оновлення на місці" category-value="in-place" >}}

{{< text syntax=bash snip_id=upgrade_ztunnel_inplace >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

{{< /tab >}}

{{< tab name="Оновлення з ревізією" category-value="revisions" >}}

{{< text syntax=bash snip_id=upgrade_ztunnel_revisioned >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system --set revision="$REVISION" --wait
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< tabset category-name="change-gateway-revision" >}}

{{< tab name="Оновлення на місці" category-value="in-place" >}}

### Оновлення чарту розгорнутого вручну шлюзу (необовʼязково) {#upgrade-manually-deployed-gateways-optional}

`Gateway`, які були [розгорнуті вручну](/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment), потрібно оновити індивідуально за допомогою Helm:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

{{< /tab >}}

{{< tab name="Оновлення з ревізією" category-value="revisions" >}}

### Оновлення waypoints та шлюзів за допомогою теґів {#upgrade-waypoints-and-gateways-using-tags}

Якщо ви дотримувалися найкращих практик, усі ваші шлюзи, робочі навантаження та простори імен використовують або стандартну версію (фактично теґ з назвою `default`), або мітку `istio.io/rev` зі значенням, встановленим у назву теґу. Тепер ви можете оновити все це до нової версії панелі даних Istio, перемістивши їх теґи, щоб вони вказували на нову версію, по черзі. Щоб переглянути всі теґи у вашому кластері, виконайте:

{{< text syntax=bash snip_id=list_tags >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/tag' -L istio\.io/tag,istio\.io/rev
{{< /text >}}

Для кожного теґу ви можете оновити теґ, виконавши наступну команду, замінивши `$MYTAG` назвою вашого теґу, а `$REVISION` назвою вашої версії:

{{< text syntax=bash snip_id=upgrade_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

Це оновить всі обʼєкти, що посилаються на цей теґ, за винятком тих, що використовують [режим ручного розгортання шлюзу](/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment), які розглянуті нижче, і sidecar, які не використовуються в режимі оточення.

Рекомендується уважно стежити за станом справності застосунків, що використовують оновлені панелі даних, перед оновленням наступного теґу. Якщо ви виявите проблему, ви можете відкотити теґ, повернувши його до вказування на назву вашої старої версії:

{{< text syntax=bash snip_id=rollback_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$OLD_REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

### Оновлення вручну розгорнутих шлюзів (необовʼязково) {#upgrade-manually-deployed-gateways-optional}

`Gateway`, які були [розгорнуті вручну](/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment), потрібно оновити індивідуально за допомогою Helm:

{{< text syntax=bash snip_id=upgrade_gateway >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

## Видалення попередньої панелі управління {#uninstall-the-previous-control-plane}

Якщо ви оновили всі компоненти панелі даних до нової ревізії панелі управління Istio і задоволені тим, що вам не потрібно виконувати відкат, ви можете видалити попередню ревізію панелі управління, виконавши:

{{< text syntax=bash snip_id=none >}}
$ helm delete istiod-"$REVISION" -n istio-system
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
