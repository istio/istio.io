---
title: Ambient та Kubernetes NetworkPolicy
description: Розуміння того, як мережева політика L4 Kubernetes NetworkPolicy з підтримкою CNI взаємодіє з режимом оточення Istio.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Kubernetes [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) дозволяє контролювати, як трафік рівня 4 досягає ваших podʼів.

`NetworkPolicy` зазвичай реалізується {{< gloss >}}CNI{{< /gloss >}}, встановленою у вашому кластері. Istio не є CNI та не керує та не реалізує `NetworkPolicy`, а в усіх випадках дотримується його — ambient не обходить і ніколи не обходитиме виконання Kubernetes `NetworkPolicy`.

Одним із наслідків цього є те, що можливо створити Kubernetes `NetworkPolicy`, що заблокує трафік Istio або іншим чином завадить роботі Istio, тому під час спільного використання `NetworkPolicy` та ambient варто звернути увагу на кілька моментів.

## Накладення трафіку Ambient та Kubernetes NetworkPolicy {#ambient-traffic-overlay-and-kubernetes-networkpolicy}

Як тільки ви додали застосунки до ambient mesh, безпечне накладення L4 від ambient тунелюватиме трафік між вашими podʼами через порт 15008. Коли захищений трафік досягне цільового podʼа з портом призначення 15008, трафік буде проксійовано назад до початкового порту призначення.

Однак `NetworkPolicy` реалізується на хості, поза podʼом. Це означає, що якщо у вас є попередньо налаштований `NetworkPolicy`, який, наприклад, забороняє вхідний трафік до ambient podʼа на всіх портах, крім 443, вам потрібно додати виняток до цього `NetworkPolicy` для порту 15008.

Наприклад, наступний `NetworkPolicy` блокуватиме вхідний трафік {{< gloss >}}HBONE{{< /gloss >}} до `my-app` на порту 15008:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
spec:
  ingress:
  - ports:
    - port: 9090
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
{{< /text >}}

і його слід змінити на

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
spec:
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
    - port: 15008
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
{{< /text >}}

якщо `my-app` доданий до ambient mesh.

## Ambient, health probes та Kubernetes NetworkPolicy {#ambient-health-probes-and-kubernetes-networkpolicy}

Проби справності Kubernetes створюють проблему та створюють особливий випадок для політики трафіку Kubernetes загалом. Вони походять від kubelet, що працює як процес на вузлі, а не від якогось іншого podʼа в кластері. Вони є текстовими та незахищеними. Ні kubelet, ні вузол Kubernetes зазвичай не мають власної криптографічної ідентичності, тому контроль доступу неможливий. Недостатньо просто дозволити весь трафік через порт перевірки справності, оскільки шкідливий трафік може використовувати цей порт так само легко, як і kubelet. Крім того, багато застосунків використовують той самий порт для перевірки справності та для законного трафіку застосунку, тому прості дозволи на основі порту є неприйнятними.

Різні реалізації CNI розвʼязують цю проблему по-різному та намагаються або обійти проблему, тихо виключаючи проби справності kubelet з нормального виконання політики, або налаштовуючи для них виключення політики.

У Istio ambient ця проблема вирішується за допомогою комбінації правил iptables і перекладу мережних адрес джерела (SNAT) для переписування лише тих пакетів, які явно походять від локального вузла, на фіксовану локальну IP-адресу, щоб їх можна було явно ігнорувати правилами виконання політики Istio як незахищений трафік перевірки справності. Локальна IP-адреса була обрана типово, оскільки зазвичай їх ігнорують для контролю ingress-egress, і, за [стандартом IETF](https://datatracker.ietf.org/doc/html/rfc3927), вони не маршрутизуються за межами локальної підмережі.

Ця поведінка прозоро вмикається, коли ви додаєте podʼи до ambient mesh, і стандартно ambient використовує локальну адресу `169.254.7.127` для ідентифікації та правильного дозволу пакетів проб справності kubelet.

Однак якщо у вашому робочому навантаженні, просторі імен або кластері вже налаштований вхідний або вихідний `NetworkPolicy`, залежно від того, який CNI ви використовуєте, пакети з цією локальною адресою можуть бути заблоковані явним `NetworkPolicy`, що призведе до того, що перевірки справності podʼів вашого застосунку почнуть не виконуватися після додавання podʼів до ambient mesh.

Наприклад, застосування наступного `NetworkPolicy` в просторі імен заблокує весь трафік (Istio чи інший) до podʼа `my-app`, **включаючи** проби справності kubelet. Залежно від вашого CNI, проби kubelet і локальні адреси можуть бути проігноровані цією політикою або заблоковані нею:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  policyTypes:
  - Ingress
{{< /text >}}

Після того, як pod буде зареєстровано в ambient mesh, пакети перевірки справності почнуть призначатися локальною адресою через SNAT, що означає, що проби справності можуть почати блокуватися вашим CNI при реалізації `NetworkPolicy`. Щоб дозволити пробам справності ambient обходити `NetworkPolicy`, явно дозвольте трафік від вузла до вашого podʼа, додавши до білого списку локальну адресу, яку використовує ambient для цього трафіку:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress-allow-kubelet-healthprobes
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
    - from:
      - ipBlock:
          cidr: 169.254.7.127/32
{{< /text >}}
