---
title: Bookinfo con una Virtual Machine
description: Ejecutar la aplicación Bookinfo con un Service MySQL ejecutándose en una virtual
  machine dentro de tu malla.
weight: 60
keywords:
- virtual-machine
- vms
aliases:
- /docs/examples/integrating-vms/
- /docs/examples/mesh-expansion/bookinfo-expanded
- /docs/examples/virtual-machines/bookinfo/
- /docs/examples/vm-bookinfo
owner: istio/wg-environments-maintainers
test: yes
---

Este ejemplo despliega la aplicación Bookinfo a través de Kubernetes con un
Service ejecutándose en una Virtual Machine (VM), e ilustra cómo controlar
esta infraestructura como una sola malla.

## Visión general

{{< image width="80%" link="./vm-bookinfo.svg" caption="Bookinfo ejecutándose en VMs" >}}

<!-- source of the drawing
https://docs.google.com/drawings/d/1G1592HlOVgtbsIqxJnmMzvy6ejIdhajCosxF1LbvspI/edit
 -->

## Antes de comenzar

- Configura Istio siguiendo las instrucciones en la
  [guía de instalación de Virtual Machine](/es/docs/setup/install/virtual-machine/).

- Despliega la aplicación de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) (en el namespace `bookinfo`).

- Crea una VM y agrégala al namespace `vm`, siguiendo los pasos en
  [Configurar la Virtual Machine](/es/docs/setup/install/virtual-machine/#configure-the-virtual-machine).

## Ejecutar MySQL en la VM

Primero instalaremos MySQL en la VM, y lo configuraremos como un backend para el Service ratings.
Todos los comandos a continuación deben ejecutarse en la VM.

Instala `mariadb`:

{{< text bash >}}
$ sudo apt-get update && sudo apt-get install -y mariadb-server
$ sudo sed -i '/bind-address/c\bind-address  = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf
{{< /text >}}

Configura la autenticación:

{{< text bash >}}
$ cat <<EOF | sudo mysql
# Grant access to root
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
# Grant root access to other IPs
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit;
EOF
$ sudo systemctl restart mysql
{{< /text >}}

Puedes encontrar detalles sobre configurar MySQL en [Mysql](https://mariadb.com/kb/en/library/download/).

En la VM agrega la base de datos ratings a mysql.

{{< text bash >}}
$ curl -LO {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql
$ mysql -u root -ppassword < mysqldb-init.sql
{{< /text >}}

Para facilitar la inspección visual de la diferencia en la salida de la aplicación Bookinfo, puedes cambiar las calificaciones que se generan usando los
siguientes comandos para inspeccionar las calificaciones:

{{< text bash >}}
$ mysql -u root -ppassword test -e "select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      5 |
|        2 |      4 |
+----------+--------+
{{< /text >}}

y para cambiar las calificaciones

{{< text bash >}}
$ mysql -u root -ppassword test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      1 |
|        2 |      4 |
+----------+--------+
 {{< /text >}}

## Exponer el Service mysql a la mesh

Cuando la Virtual Machine se inicia, se registrará automáticamente en la mesh.
Sin embargo, al igual que cuando se crea un Pod, aún necesitamos crear un Service antes de poder acceder a él fácilmente.

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

## Usar el Service mysql

El Service ratings en Bookinfo usará la DB en la máquina. Para verificar que funciona, crea la versión 2 del Service ratings que usa la base de datos mysql en la VM. Luego especifica reglas de enrutamiento que fuerzan al Service review a usar la versión 2 de ratings.

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml@
{{< /text >}}

Crea reglas de enrutamiento que forzarán a Bookinfo a usar el backend ratings:

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml@
{{< /text >}}

Puedes verificar que la salida de la aplicación Bookinfo muestra 1 estrella de Reviewer1 y 4 estrellas de Reviewer2 o cambiar las calificaciones en tu VM y ver los
resultados.

## Alcanzar los Services de Kubernetes desde la Virtual Machine

En el ejemplo anterior, tratamos nuestra Virtual Machine solo como un servidor.
También podemos llamar sin problemas a los Services de Kubernetes desde nuestra Virtual Machine:

{{< text bash >}}
$ curl productpage.bookinfo:9080/productpage
...
<title>Simple Bookstore App</title>
...
{{< /text >}}

El [DNS proxying](/es/docs/ops/configuration/traffic-management/dns-proxy/) de Istio configura automáticamente el DNS para la Virtual Machine, permitiéndonos hacer llamadas a los hostnames de Kubernetes.

## Limpieza

- Elimina la aplicación de ejemplo `Bookinfo` y su configuración siguiendo los pasos en
[limpieza de `Bookinfo`](/es/docs/examples/bookinfo/#cleanup).
- Elimina el Service `mysqldb`:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl delete service mysqldb
    {{< /text >}}

- Limpia la VM siguiendo los pasos en [desinstalación de Virtual Machine](/es/docs/setup/install/virtual-machine/#uninstall).
