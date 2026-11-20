---
title: Solución de problemas multiclúster
description: Describe herramientas y técnicas para diagnosticar problemas en instalaciones multiclúster y multi-red.
weight: 90
keywords: [debug,multicluster,multi-network,envoy]
owner: istio/wg-environments-maintainers
test: no
---

Esta página describe cómo solucionar problemas de Istio desplegado en varios clústeres y/o redes.
Antes de leerla, deberías seguir los pasos de [Instalación multiclúster](/es/docs/setup/install/multicluster/)
y leer la guía [Modelos de despliegue](/es/docs/ops/deployment/deployment-models/).

## Balanceo de carga entre clústeres {#cross-cluster-load-balancing}

El problema más común, aunque también muy amplio, de las instalaciones multi-red es que el balanceo de carga entre clústeres no funciona. Normalmente se manifiesta en que solo ves respuestas de la instancia de un Service que está en el clúster local:

{{< text bash >}}
$ for i in $(seq 10); do kubectl --context=$CTX_CLUSTER1 -n sample exec curl-dd98b5f48-djwdw -c curl -- curl -s helloworld:5000/hello; done
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
...
{{< /text >}}

Al seguir la guía para [verificar la instalación multiclúster](/es/docs/setup/install/multicluster/verify/),
esperaríamos respuestas tanto de `v1` como de `v2`, lo que indica que el tráfico llega a ambos clústeres.

Hay muchas causas posibles para este problema:

### Problemas de conectividad y de firewall {#connectivity-and-firewall-issues}

En algunos entornos puede no ser evidente que un firewall esté bloqueando el tráfico entre tus clústeres. Es posible
que el tráfico `ICMP` (ping) funcione, pero que el tráfico HTTP y otros tipos de tráfico no. Esto puede manifestarse como un tiempo de espera agotado o,
en algunos casos, como un error más confuso, por ejemplo:

{{< text plain >}}
upstream connect error or disconnect/reset before headers. reset reason: local reset, transport failure reason: TLS error: 268435612:SSL routines:OPENSSL_internal:HTTP_REQUEST
{{< /text >}}

Aunque Istio ofrece capacidades de descubrimiento de servicios para facilitarlo, el tráfico entre clústeres debería funcionar igualmente
sin Istio si los pods de cada clúster están en una misma red. Para descartar problemas de TLS/mTLS, puedes hacer una prueba manual
de tráfico con pods sin sidecars de Istio.

En cada clúster, crea un namespace nuevo para esta prueba. _No_ habilites la inyección de sidecar:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace uninjected-sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace uninjected-sample
{{< /text >}}

Luego despliega las mismas aplicaciones que se usan en [verificar la instalación multiclúster](/es/docs/setup/install/multicluster/verify/):

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v1 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v2 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/curl/curl.yaml -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/curl/curl.yaml -n uninjected-sample
{{< /text >}}

Verifica que haya un pod helloworld en ejecución en `cluster2` usando el flag `-o wide`, para poder obtener la IP del pod:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" -n uninjected-sample get pod -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
curl-557747455f-jdsd8            1/1     Running   0          41s   10.100.0.2   node-2   <none>           <none>
helloworld-v2-54df5f84b-z28p5    1/1     Running   0          43s   10.100.0.1   node-1   <none>           <none>
{{< /text >}}

Anota el valor de la columna `IP` de `helloworld`. En este caso, es `10.100.0.1`:

{{< text bash >}}
$ REMOTE_POD_IP=10.100.0.1
{{< /text >}}

A continuación, intenta enviar tráfico desde el pod `curl` de `cluster1` directamente a esta IP de pod:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n uninjected-sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n uninjected-sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS $REMOTE_POD_IP:5000/hello
Hello version: v2, instance: helloworld-v2-54df5f84b-z28p5
{{< /text >}}

Si funciona, solo debería haber respuestas de `helloworld-v2`. Repite los pasos, pero envía tráfico desde `cluster2`
hacia `cluster1`.

Si esto funciona, puedes descartar problemas de conectividad. Si no, la causa del problema puede estar fuera de tu
configuración de Istio.

### Balanceo de carga por localidad {#locality-load-balancing}

El [balanceo de carga por localidad](/es/docs/tasks/traffic-management/locality-load-balancing/failover/#configure-locality-failover)
se puede usar para que los clientes prefieran enviar el tráfico al destino más cercano. Si los clústeres
están en localidades diferentes (región/zona), el balanceo de carga por localidad dará preferencia al clúster local y está funcionando según lo
previsto. Si el balanceo de carga por localidad está deshabilitado, o si los clústeres están en la misma localidad, puede haber otro problema.

### Configuración de confianza {#trust-configuration}

El tráfico entre clústeres, al igual que el tráfico dentro de un clúster, depende de una raíz de confianza común entre los proxies. Por defecto,
cada instalación de Istio usa sus propias autoridades de certificación raíz, generadas de forma individual. En un entorno multiclúster,
debemos configurar manualmente una raíz de confianza compartida. Sigue la sección Conectar certificados más abajo o lee [Modelos de identidad y confianza](/es/docs/ops/deployment/deployment-models/#identity-and-trust-models)
para obtener más información.

**Conectar certificados:**

Para verificar que los certificados estén configurados correctamente, puedes comparar el certificado raíz de cada clúster:

{{< text bash >}}
$ diff \
   <(kubectl --context="${CTX_CLUSTER1}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}') \
   <(kubectl --context="${CTX_CLUSTER2}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}')
{{< /text >}}

Si los certificados raíz no coinciden o el secreto ni siquiera existe, puedes seguir la guía [Conectar certificados de CA](/es/docs/tasks/security/cert-management/plugin-ca-cert/)
y asegurarte de ejecutar los pasos en cada clúster.

### Diagnóstico paso a paso {#step-by-step-diagnosis}

Si ya revisaste las secciones anteriores y sigues teniendo problemas, es hora de investigar un poco más a fondo.

Los siguientes pasos asumen que estás siguiendo la [verificación con HelloWorld](/es/docs/setup/install/multicluster/verify/).
Antes de continuar, asegúrate de que tanto `helloworld` como `curl` estén desplegados en cada clúster.

Desde cada clúster, busca los endpoints que tiene el servicio `curl` para `helloworld`:

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint curl-dd98b5f48-djwdw.sample | grep helloworld
{{< /text >}}

La información para solucionar problemas varía según el clúster que origina el tráfico:

{{< tabset category-name="source-cluster" >}}

{{< tab name="Primary cluster" category-value="primary" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint curl-dd98b5f48-djwdw.sample | grep helloworld
10.0.0.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

Solo se muestra un endpoint, lo que indica que el control plane no puede leer los endpoints del clúster remoto.
Verifica que los secretos remotos estén configurados correctamente.

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* Si falta el secreto, créalo.
* Si el secreto existe:
    * Revisa la configuración del secreto. Asegúrate de que el nombre del clúster se use como clave de datos para el `kubeconfig` remoto.
    * Si el secreto parece correcto, revisa los registros de `istiod` en busca de problemas de conectividad o de permisos al acceder al
     API server de Kubernetes remoto. Los mensajes de registro pueden incluir `Failed to add remote cluster from secret` junto con el
     motivo del error.

{{< /tab >}}

{{< tab name="Remote cluster" category-value="remote" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER2 proxy-config endpoint curl-dd98b5f48-djwdw.sample | grep helloworld
10.0.1.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

Solo se muestra un endpoint, lo que indica que el control plane no puede leer los endpoints del clúster remoto.
Verifica que los secretos remotos estén configurados correctamente.

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* Si falta el secreto, créalo.
* Si el secreto existe y el endpoint es un pod del clúster **primario**:
    * Revisa la configuración del secreto. Asegúrate de que el nombre del clúster se use como clave de datos para el `kubeconfig` remoto.
    * Si el secreto parece correcto, revisa los registros de `istiod` en busca de problemas de conectividad o de permisos al acceder al
     API server de Kubernetes remoto. Los mensajes de registro pueden incluir `Failed to add remote cluster from secret` junto con el
     motivo del error.
* Si el secreto existe y el endpoint es un pod del clúster **remoto**:
    * El proxy está leyendo la configuración de un istiod que está dentro del clúster remoto. Cuando un clúster remoto tiene un istiod
     dentro del propio clúster, solo está pensado para la inyección de sidecar y como CA. Puedes verificar si este es el problema buscando
     un Service llamado `istiod-remote` en el namespace `istio-system`. Si no existe, vuelve a instalar asegurándote de que
     `values.global.remotePilotAddress` esté configurado.

{{< /tab >}}

{{< tab name="Multi-Network" category-value="multi-primary" >}}

Los pasos para clústeres primarios y remotos también se aplican a multi-red, aunque en multi-red hay un caso adicional:

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint curl-dd98b5f48-djwdw.sample | grep helloworld
10.0.5.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
10.0.6.13:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

En multi-red, esperamos que una de las IP de los endpoints coincida con la IP pública del gateway east-west del clúster remoto. Ver
varias IP de pods indica una de estas dos cosas:

* No se puede determinar la dirección del gateway de la red remota.
* No se puede determinar la red del pod cliente o del pod servidor.

**No se puede determinar la dirección del gateway de la red remota:**

En el clúster remoto al que no se puede llegar, comprueba que el Service tenga una IP externa:

{{< text bash >}}
$ kubectl -n istio-system get service -l "istio=eastwestgateway"
NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                                                           AGE
istio-eastwestgateway    LoadBalancer   10.8.17.119   <PENDING>        15021:31781/TCP,15443:30498/TCP,15012:30879/TCP,15017:30336/TCP   76m
{{< /text >}}

Si `EXTERNAL-IP` se queda en `<PENDING>`, es posible que el entorno no admita servicios de tipo `LoadBalancer`. En ese caso,
puede ser necesario personalizar la sección `spec.externalIPs` del Service para asignar manualmente al gateway una IP accesible
desde fuera del clúster.

Si la IP externa existe, comprueba que el Service incluya la etiqueta `topology.istio.io/network` con el valor
correcto. Si no es correcto, vuelve a instalar el gateway y asegúrate de establecer el flag --network en el script de generación.

**No se puede determinar la red del cliente o del servidor.**

En el pod de origen, revisa los metadatos del proxy.

{{< text bash >}}
$ kubectl get pod $CURL_POD_NAME \
  -o jsonpath="{.spec.containers[*].env[?(@.name=='ISTIO_META_NETWORK')].value}"
{{< /text >}}

{{< text bash >}}
$ kubectl get pod $HELLOWORLD_POD_NAME \
  -o jsonpath="{.metadata.labels.topology\.istio\.io/network}"
{{< /text >}}

Si alguno de estos valores no está configurado o tiene un valor incorrecto, istiod puede tratar los proxies de origen y del cliente como si estuvieran en la misma red y enviar endpoints de la red local.
Si no están configurados, comprueba que `values.global.network` se haya configurado correctamente durante la instalación o que el webhook de inyección esté configurado correctamente.

Istio determina la red de un pod mediante la etiqueta `topology.istio.io/network`, que se establece durante la inyección. Para
los pods sin inyección, Istio se basa en la etiqueta `topology.istio.io/network` establecida en el namespace del sistema del clúster.

En cada clúster, comprueba la red:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get ns istio-system -ojsonpath='{.metadata.labels.topology\.istio\.io/network}'
{{< /text >}}

Si el comando anterior no muestra el nombre de red esperado, establece la etiqueta:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
