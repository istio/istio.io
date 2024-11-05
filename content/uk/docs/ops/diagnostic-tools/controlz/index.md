---
title: Інтроспекція Istiod
description: Описує, як використовувати ControlZ для отримання інформації про працюючий компонент istiod.
weight: 60
keywords: [ops]
aliases:
  - /uk/help/ops/controlz
  - /uk/docs/ops/troubleshooting/controlz
owner: istio/wg-user-experience-maintainers
test: no
---

Istiod побудований з використанням гнучкої інтроспекційної системи, яка називається ControlZ, що полегшує перевірку та маніпулювання внутрішнім станом екземпляра istiod. Istiod відкриває порт, який можна використовувати з вебоглядача для отримання інтерактивного перегляду його стану, або через REST для доступу та контролю з зовнішніх інструментів.

Коли Istiod запускається, реєструється повідомлення, яке вказує IP-адресу та порт для підключення до ControlZ.

{{< text plain >}}
2020-08-04T23:28:48.889370Z     info    ControlZ доступний на 100.76.122.230:9876
{{< /text >}}

Ось приклад інтерфейсу ControlZ:

{{< image width="90%" link="./ctrlz.png" caption="Інтерфейс користувача ControlZ" >}}

Щоб отримати доступ до сторінки ControlZ istiod, ви можете перенаправити порт його точки доступу ControlZ локально та приєднатись через ваш локальний оглядач:

{{< text bash >}}
$ istioctl dashboard controlz deployment/istiod.istio-system
{{< /text >}}

Це перенаправить сторінку ControlZ компонента на `http://localhost:9876` для віддаленого доступу.
