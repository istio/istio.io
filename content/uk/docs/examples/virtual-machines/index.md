---
title: Bookinfo у віртуальній машині
description: Запустіть застосунок Bookinfo з сервісом MySQL, що працює у віртуальній машині в межах вашої мережі.
weight: 60
keywords:
- virtual-machine
- vms
aliases:
- /uk/docs/examples/integrating-vms/
- /uk/docs/examples/mesh-expansion/bookinfo-expanded
- /uk/docs/examples/virtual-machines/bookinfo/
- /uk/docs/examples/vm-bookinfo
owner: istio/wg-environments-maintainers
test: yes
---

Цей приклад розгортає застосунок Bookinfo у Kubernetes з одним сервісом, що працює на віртуальній машині (VM), і ілюструє, як контролювати цю інфраструктуру як єдину мережу.

## Огляд {#overview}

{{< image width="80%" link="./vm-bookinfo.svg" caption="Bookinfo, що працює у VM" >}}

<!-- source of the drawing
https://docs.google.com/drawings/d/1G1592HlOVgtbsIqxJnmMzvy6ejIdhajCosxF1LbvspI/edit
 -->

## Перед тим як почати {#before-you-begin}

- Налаштуйте Istio, дотримуючись інструкцій з [посібника з встановлення віртуальних машин](/docs/setup/install/virtual-machine/).

- Розгорніть [демонстраційний застосунок Bookinfo](/docs/examples/bookinfo/) (у просторі імен `bookinfo`).

- Створіть VM і додайте її до простору імен `vm`, дотримуючись кроків з [Налаштування віртуальної машини](/docs/setup/install/virtual-machine/#configure-the-virtual-machine).

## Запуск MySQL на VM {#running-mysql-on-the-vm}

Спочатку ми встановимо MySQL у VM і налаштуємо його як бекенд для сервісу рейтингу. Всі команди нижче потрібно виконати у VM.

Встановіть `mariadb`:

{{< text bash >}}
$ sudo apt-get update && sudo apt-get install -y mariadb-server
$ sudo sed -i '/bind-address/c\bind-address  = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf
{{< /text >}}

Налаштуйте автентифікацію:

{{< text bash >}}
$ cat <<EOF | sudo mysql
# Надати доступ root
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
# Надати доступ root для інших IP
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit;
EOF
$ sudo systemctl restart mysql
{{< /text >}}

Деталі налаштування MySQL можна знайти у документації [Mysql](https://mariadb.com/kb/en/library/download/).

У VM додайте базу даних рейтингів до mysql.

{{< text bash >}}
$ curl -LO {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql
$ mysql -u root -ppassword < mysqldb-init.sql
{{< /text >}}

Щоб легко візуально перевірити різницю у виводі застосунку Bookinfo, ви можете змінити рейтинги, що генеруються, використовуючи наступні команди для перевірки рейтингів:

{{< text bash >}}
$ mysql -u root -ppassword test -e "select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      5 |
|        2 |      4 |
+----------+--------+
{{< /text >}}

і для зміни рейтингів

{{< text bash >}}
$ mysql -u root -ppassword test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      1 |
|        2 |      4 |
+----------+--------+
 {{< /text >}}

## Експонування сервісу mysql у мережу {#expose-the-mysql-service-to-the-mesh}

Коли віртуальна машина запущена, вона автоматично буде зареєстрована в мережі. Однак, як і при створенні Pod, нам потрібно створити Сервіс, щоб ми могли легко до нього доступитися.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f - -n vm
apiVersion: v1
kind: Service
metadata:
  name: mysqldb
  labels:
    app: mysqldb
spec:
  ports:
  - port: 3306
    name: tcp
  selector:
    app: mysqldb
EOF
{{< /text >}}

## Використання сервісу mysql {#using-the-mysql-service}

Сервіс рейтингів у Bookinfo буде використовувати БД на машині. Щоб перевірити, чи це працює, створіть версію 2 сервісу рейтингів, що використовує mysql db на VM. Потім вкажіть правила маршрутизації, які примусово використовують версію 2 сервісу рейтингів.

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml@
{{< /text >}}

Створіть правила маршрутизації, які примусово використовують бекенд рейтингів у Bookinfo:

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml@
{{< /text >}}

Ви можете перевірити, що вивід Bookinfo показує 1 зірку від Reviewer1 і 4 зірки від Reviewer2 або змініть рейтинги у вашій VM і перегляньте результати.

## Доступ до сервісів Kubernetes з віртуальної машини {#reaching-kubernetes-services-from-the-virtual-machine}

У наведеному прикладі ми розглядали нашу віртуальну машину лише як сервер. Ми також можемо безперешкодно викликати сервіси Kubernetes з нашої віртуальної машини:

{{< text bash >}}
$ curl productpage.bookinfo:9080/productpage
...
<title>Simple Bookstore App</title>
...
{{< /text >}}

[DNS-проксіювання](/docs/ops/configuration/traffic-management/dns-proxy/) в Istio автоматично налаштовує DNS для віртуальної машини, що дозволяє нам викликати хости Kubernetes.

## Очищення {#cleanup}

- Видаліть демонстраційний застосунок `Bookinfo` та його конфігурацію, дотримуючись кроків з
[`Очищення Bookinfo`](/docs/examples/bookinfo/#cleanup).
- Видаліть Сервіс `mysqldb`:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl delete service mysqldb
    {{< /text >}}

- Виконайте очищення VM, дотримуючись кроків з [Видалення віртуальної машини](/docs/setup/install/virtual-machine/#uninstall).
