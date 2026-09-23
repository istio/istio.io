---
title: Terminación TLS de Sidecar de Entrada
description: Describe cómo terminar el tráfico TLS en un sidecar sin usar un Ingress Gateway.
weight: 30
keywords: [traffic-management,ingress,https]
owner: istio/wg-networking-maintainers
test: yes
---

En un despliegue de mesh de Istio regular, la terminación TLS para las solicitudes descendentes se realiza en el Ingress Gateway.
Aunque esto satisface la mayoría de los casos de uso, para algunos (como un API Gateway en la mesh) el Ingress Gateway no es necesariamente necesario. Esta tarea muestra cómo eliminar el salto adicional introducido por el Ingress Gateway de Istio y permitir que el sidecar de Envoy, que se ejecuta junto con la aplicación, realice la terminación TLS para las solicitudes que provienen de fuera de la service mesh.

El service HTTPS de ejemplo utilizado para esta tarea es un service [httpbin](https://httpbin.org) simple.
En los siguientes pasos, desplegará el service httpbin dentro de su service mesh y lo configurará.

{{< boilerplate experimental-feature-warning >}}

## Antes de empezar

*   Configure Istio siguiendo las instrucciones de la [guía de instalación](/es/docs/setup/), habilitando la feature experimental
    `ENABLE_TLS_ON_SIDECAR_INGRESS`.

    {{< text bash >}}
    $ istioctl install --set profile=default --set values.pilot.env.ENABLE_TLS_ON_SIDECAR_INGRESS=true
    {{< /text >}}

*   Cree el namespace de prueba donde se desplegará el service `httpbin` de destino. Asegúrese de habilitar la inyección de sidecar
    para el namespace.

    {{< text bash >}}
    $ kubectl create ns test
    $ kubectl label namespace test istio-injection=enabled
    {{< /text >}}

## Habilitar mTLS global

Aplique la siguiente política `PeerAuthentication` para requerir tráfico mTLS para todos los workloads en la mesh.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

## Deshabilitar PeerAuthentication para el puerto httpbin expuesto externamente

Deshabilite `PeerAuthentication` para el puerto del service httpbin que realizará la terminación TLS de entrada en el sidecar. Tenga en cuenta que este es el `targetPort` del service httpbin que debe usarse exclusivamente para la comunicación externa.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: disable-peer-auth-for-external-mtls-port
  namespace: test
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    9080:
      mode: DISABLE
EOF
{{< /text >}}

## Generar certificado de CA, certificado/clave de servidor y certificado/clave de cliente

Para esta tarea, puede usar su herramienta favorita para generar certificados y claves. Los comandos a continuación usan
[openssl](https://man.openbsd.org/openssl.1):

{{< text bash >}}
$ #CA es example.com
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
$ #El servidor es httpbin.test.svc.cluster.local
$ openssl req -out httpbin.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout httpbin.test.svc.cluster.local.key -subj "/CN=httpbin.test.svc.cluster.local/O=httpbin organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in httpbin.test.svc.cluster.local.csr -out httpbin.test.svc.cluster.local.crt
$ #El cliente es client.test.svc.cluster.local
$ openssl req -out client.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout client.test.svc.cluster.local.local.key -subj "/CN=client.test.svc.cluster.local/O=client organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.test.svc.cluster.local.csr -out client.test.svc.cluster.local.crt
{{< /text >}}

## Crear secretos de k8s para los certificados y claves

{{< text bash >}}
$ kubectl -n test create secret generic httpbin-mtls-termination-cacert --from-file=ca.crt=./example.com.crt
$ kubectl -n test create secret tls httpbin-mtls-termination --cert ./httpbin.test.svc.cluster.local.crt --key ./httpbin.test.svc.cluster.local.key
{{< /text >}}

## Desplegar el service de prueba httpbin

Cuando se crea el despliegue de httpbin, necesitamos usar anotaciones `userVolumeMount` en el despliegue para montar los certificados para el sidecar istio-proxy.
Tenga en cuenta que este paso solo es necesario porque Istio actualmente no admite `credentialName` en una configuración de sidecar.

{{< text yaml >}}
sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
{{< /text >}}

Use el siguiente comando para desplegar el service `httpbin` con la configuración `userVolumeMount` requerida:

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - port: 8443
    name: https
    targetPort: 9080
  - port: 8080
    name: http
    targetPort: 9081
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
      annotations:
        sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
        sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF
{{< /text >}}

## Configurar httpbin para habilitar mTLS externo

Este es el paso central para esta feature. Usando la API `Sidecar`, configure los ajustes TLS de entrada.
El modo TLS puede ser `SIMPLE` o `MUTUAL`. Este ejemplo usa `MUTUAL`.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: ingress-sidecar
  namespace: test
spec:
  workloadSelector:
    labels:
      app: httpbin
      version: v1
  ingress:
  - port:
      number: 9080
      protocol: HTTPS
      name: external
    defaultEndpoint: 0.0.0.0:80
    tls:
      mode: MUTUAL
      privateKey: "/etc/istio/tls-certs/tls.key"
      serverCertificate: "/etc/istio/tls-certs/tls.crt"
      caCertificates: "/etc/istio/tls-ca-certs/ca.crt"
  - port:
      number: 9081
      protocol: HTTP
      name: internal
    defaultEndpoint: 0.0.0.0:80
EOF
{{< /text >}}

## Verificación

Ahora que el servidor httpbin está desplegado y configurado, levante dos clientes para probar la conectividad de extremo a extremo tanto desde dentro como desde fuera de la mesh:
1. Un cliente interno (curl) en el mismo namespace (test) que el service httpbin, con sidecar inyectado.
1. Un cliente externo (curl) en el namespace predeterminado (es decir, fuera de la service mesh).

{{< text bash >}}
$ kubectl apply -f samples/curl/curl.yaml
$ kubectl -n test apply -f samples/curl/curl.yaml
{{< /text >}}

Ejecute los siguientes comandos para verificar que todo está en funcionamiento y configurado correctamente.

{{< text bash >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
curl-557747455f-xx88g    1/1     Running   0          4m14s
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n test
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-5bbdbd6588-z9vbs   2/2     Running   0          8m44s
curl-557747455f-brzf6      2/2     Running   0          6m57s
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n test
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
httpbin   ClusterIP   10.100.78.113   <none>        8443/TCP,8080/TCP   10m
curl      ClusterIP   10.110.35.153   <none>        80/TCP              8m49s
{{< /text >}}

En el siguiente comando, reemplace `httpbin-5bbdbd6588-z9vbs` con el nombre de su pod httpbin.

{{< text bash >}}
$ istioctl proxy-config secret httpbin-5bbdbd6588-z9vbs.test
RESOURCE NAME                                                           TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
file-cert:/etc/istio/tls-certs/tls.crt~/etc/istio/tls-certs/tls.key     Cert Chain     ACTIVE     true           1                                           2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
default                                                                 Cert Chain     ACTIVE     true           329492464719328863283539045344215802956     2022-02-15T09:55:46Z     2022-02-14T09:53:46Z
ROOTCA                                                                  CA             ACTIVE     true           204427760222438623495455009380743891800     2032-02-07T16:58:00Z     2022-02-09T16:58:00Z
file-root:/etc/istio/tls-ca-certs/ca.crt                                Cert Chain     ACTIVE     true           14033888812979945197                        2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
{{< /text >}}

### Verificar la conectividad de mesh interna en el puerto 8080

{{< text bash >}}
$ export INTERNAL_CLIENT=$(kubectl -n test get pod -l app=curl -o jsonpath={.items..metadata.name})
$ kubectl -n test exec "${INTERNAL_CLIENT}" -c curl -- curl -IsS "http://httpbin:8080/status/200"
HTTP/1.1 200 OK
server: envoy
date: Mon, 24 Oct 2022 09:04:52 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 5
{{< /text >}}

### Verificar la conectividad de mesh externa a interna en el puerto 8443

Para verificar el tráfico mTLS desde un cliente externo, primero copie el certificado de CA y el certificado/clave de cliente al cliente curl que se ejecuta en el namespace predeterminado.

{{< text bash >}}
$ export EXTERNAL_CLIENT=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
$ kubectl cp client.test.svc.cluster.local.key default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp client.test.svc.cluster.local.crt default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp example.com.crt default/"${EXTERNAL_CLIENT}":/tmp/ca.crt
{{< /text >}}

Ahora que los certificados están disponibles para el cliente curl externo, puede verificar la conectividad desde este al service httpbin interno usando el siguiente comando.

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c curl -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "https://httpbin.test.svc.cluster.local:8443/status/200"
server: istio-envoy
date: Mon, 24 Oct 2022 09:05:31 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 4
x-envoy-decorator-operation: ingress-sidecar.test:9080/*
{{< /text >}}

Además de verificar la conectividad mTLS externa a través del puerto de entrada 8443, también es importante verificar que el puerto 8080 no acepte ningún tráfico mTLS externo.

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c curl -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "http://httpbin.test.svc.cluster.local:8080/status/200"
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
{{< /text >}}

## Limpieza del ejemplo de terminación mTLS

1.  Elimine los recursos de Kubernetes creados:

    {{< text bash >}}
    $ kubectl delete secret httpbin-mtls-termination httpbin-mtls-termination-cacert -n test
    $ kubectl delete service httpbin curl -n test
    $ kubectl delete deployment httpbin curl -n test
    $ kubectl delete namespace test
    $ kubectl delete service curl
    $ kubectl delete deployment curl
    {{< /text >}}

1.  Elimine los certificados y claves privadas:

    {{< text bash >}}
    $ rm example.com.crt example.com.key httpbin.test.svc.cluster.local.crt httpbin.test.svc.cluster.local.key httpbin.test.svc.cluster.local.csr \
        client.test.svc.cluster.local.crt client.test.svc.cluster.local.key client.test.svc.cluster.local.csr
    {{< /text >}}

1.  Desinstale Istio de su cluster:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
