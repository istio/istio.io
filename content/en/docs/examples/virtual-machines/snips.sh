#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/examples/virtual-machines/index.md
####################################################################################################

snip_running_mysql_on_the_vm_1() {
sudo apt-get update && sudo apt-get install -y mariadb-server
sudo sed -i '/bind-address/c\bind-address  = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf
}

snip_running_mysql_on_the_vm_2() {
cat <<EOF | sudo mysql
# Grant access to root
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
# Grant root access to other IPs
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit;
EOF
sudo systemctl restart mysql
}

snip_running_mysql_on_the_vm_3() {
curl -LO https://raw.githubusercontent.com/istio/istio/release-1.15/samples/bookinfo/src/mysql/mysqldb-init.sql
mysql -u root -ppassword < mysqldb-init.sql
}

snip_running_mysql_on_the_vm_4() {
mysql -u root -ppassword test -e "select * from ratings;"
}

! read -r -d '' snip_running_mysql_on_the_vm_4_out <<\ENDSNIP
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      5 |
|        2 |      4 |
+----------+--------+
ENDSNIP

snip_running_mysql_on_the_vm_5() {
mysql -u root -ppassword test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
}

! read -r -d '' snip_running_mysql_on_the_vm_5_out <<\ENDSNIP
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      1 |
|        2 |      4 |
+----------+--------+
ENDSNIP

snip_expose_the_mysql_service_to_the_mesh_1() {
cat <<EOF | kubectl apply -f - -n vm
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
}

snip_using_the_mysql_service_1() {
kubectl apply -n bookinfo -f samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml
}

snip_using_the_mysql_service_2() {
kubectl apply -n bookinfo -f samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml
}

snip_reaching_kubernetes_services_from_the_virtual_machine_1() {
curl productpage.bookinfo:9080
}

! read -r -d '' snip_reaching_kubernetes_services_from_the_virtual_machine_1_out <<\ENDSNIP
...
    <title>Simple Bookstore App</title>
...
ENDSNIP
