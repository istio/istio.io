---
title: Depuración de máquinas virtuales
description: Describe herramientas y técnicas para diagnosticar problemas con máquinas virtuales.
weight: 80
keywords: [debug,virtual-machines,envoy]
owner: istio/wg-environments-maintainers
test: n/a
---

Esta página describe cómo solucionar problemas de Istio desplegado en máquinas virtuales.
Antes de leerla, deberías seguir los pasos de [Instalación en máquinas virtuales](/es/docs/setup/install/virtual-machine/).
Además, [Arquitectura de máquinas virtuales](/es/docs/ops/deployment/vm-architecture/) puede ayudarte a entender cómo interactúan los componentes.

Solucionar problemas de una instalación de Istio en máquinas virtuales es similar a solucionar problemas de proxies que se ejecutan dentro de Kubernetes, pero hay algunas diferencias clave que debes tener en cuenta.

Aunque gran parte de la información está disponible en ambas plataformas, la forma de acceder a ella es diferente.

## Monitoreo del estado {#monitoring-health}

El sidecar de Istio normalmente se ejecuta como una unidad de `systemd`. Para asegurarte de que funciona correctamente, puedes comprobar su estado:

{{< text bash >}}
$ systemctl status istio
{{< /text  >}}

Además, puedes comprobar el estado del sidecar mediante programación en su endpoint de salud:

{{< text bash >}}
$ curl localhost:15021/healthz/ready -I
{{< /text  >}}

## Registros {#logs}

Los registros del proxy de Istio se encuentran en varios lugares.

Para acceder a los registros de `systemd`, que contienen detalles sobre la inicialización del proxy:

{{< text bash >}}
$ journalctl -f -u istio -n 1000
{{< /text  >}}

El proxy redirige `stderr` y `stdout` a `/var/log/istio/istio.err.log` y `/var/log/istio/istio.log`, respectivamente.
Para verlos en un formato similar al de `kubectl`:

{{< text bash >}}
$ tail /var/log/istio/istio.err.log /var/log/istio/istio.log -Fq -n 100
{{< /text  >}}

Puedes modificar los niveles de registro cambiando el archivo de configuración `cluster.env`. Asegúrate de reiniciar `istio` si ya está en ejecución:

{{< text bash >}}
$ echo "ISTIO_AGENT_FLAGS=\"--log_output_level=dns:debug --proxyLogLevel=debug\"" >> /var/lib/istio/envoy/cluster.env
$ systemctl restart istio
{{< /text  >}}

## Iptables

Para asegurarte de que las reglas de `iptables` se aplicaron correctamente:

{{< text bash >}}
$ sudo iptables-save
...
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
{{< /text  >}}

## Istioctl

La mayoría de los comandos de `istioctl` funcionan correctamente con máquinas virtuales. Por ejemplo, puedes usar `istioctl proxy-status` para ver todos los proxies conectados:

{{< text bash >}}
$ istioctl proxy-status
NAME           CDS        LDS        EDS        RDS      ISTIOD                    VERSION
vm-1.default   SYNCED     SYNCED     SYNCED     SYNCED   istiod-789ffff8-f2fkt     {{< istio_full_version >}}
{{< /text  >}}

Sin embargo, `istioctl proxy-config` depende de funcionalidades de Kubernetes para conectarse a un proxy, lo que no funciona con máquinas virtuales.
En su lugar, puedes pasarle un archivo que contenga el volcado de configuración de Envoy. Por ejemplo:

{{< text bash >}}
$ curl -s localhost:15000/config_dump | istioctl proxy-config clusters --file -
SERVICE FQDN                            PORT      SUBSET  DIRECTION     TYPE
istiod.istio-system.svc.cluster.local   443       -       outbound      EDS
istiod.istio-system.svc.cluster.local   15010     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15012     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15014     -       outbound      EDS
{{< /text  >}}

## Registro automático {#automatic-registration}

Cuando una máquina virtual se conecta a Istiod, se crea automáticamente un `WorkloadEntry`. Esto permite
que la máquina virtual pase a formar parte de un `Service`, de forma similar a un `Endpoint` en Kubernetes.

Para comprobar que se crean correctamente:

{{< text bash >}}
$ kubectl get workloadentries
NAME             AGE   ADDRESS
vm-10.128.0.50   14m   10.128.0.50
{{< /text  >}}

## Certificados {#certificates}

Las máquinas virtuales gestionan los certificados de forma diferente a los pods de Kubernetes, que usan un token de cuenta de servicio proporcionado por Kubernetes
para autenticarse y renovar los certificados de TLS mutuo (mTLS). En su lugar, usan las credenciales mTLS existentes para autenticarse ante la autoridad de certificación y
renovar los certificados.

Puedes ver el estado de estos certificados de la misma forma que en Kubernetes:

{{< text bash >}}
$ curl -s localhost:15000/config_dump | ./istioctl proxy-config secret --file -
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           251932493344649542420616421203546836446     2021-01-29T18:07:21Z     2021-01-28T18:07:21Z
ROOTCA            CA             ACTIVE     true           81663936513052336343895977765039160718      2031-01-26T17:54:44Z     2021-01-28T17:54:44Z
{{< /text  >}}

Además, los certificados se guardan en disco para que no se pierda el estado en caso de interrupciones o reinicios.

{{< text bash >}}
$ ls /etc/certs
cert-chain.pem  key.pem  root-cert.pem
{{< /text  >}}
