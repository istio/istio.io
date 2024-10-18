---
---
Отримане зіставлення між ревізіями, теґами та просторами імен виглядає наступним чином:

{{< image width="90%"
link="/uk/docs/setup/upgrade/canary/revision-tags-before.svg"
caption="Два простори імен вказані на prod-stable, і один на prod-canary"
>}}

Оператор кластера може переглядати це зіставлення разом із протеґованими просторами імен за допомогою команди `istioctl tag list`:

{{< text bash >}}
$ istioctl tag list
TAG         REVISION NAMESPACES
default     {{< istio_previous_version_revision >}}-1   ...
prod-canary {{< istio_full_version_revision >}}   ...
prod-stable {{< istio_previous_version_revision >}}-1   ...
{{< /text >}}

Після того як оператор кластера впевнений у стабільності панелі управління з теґом `prod-canary`, простори імен, помічені як `istio.io/rev=prod-stable`, можна оновити однією дією, змінивши теґ ревізії `prod-stable`, щоб вказувати на новішу ревізію `{{< istio_full_version_revision >}}`.
