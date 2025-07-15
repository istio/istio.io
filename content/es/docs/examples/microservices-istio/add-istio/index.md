---
title: Habilitar Istio en productpage
overview: Despliega el control plane de Istio y habilita Istio en un único microservicio.
weight: 60
owner: istio/wg-docs-maintainers
test: no
---

Como viste en el módulo anterior, Istio mejora Kubernetes al proporcionarte
funcionalidad para operar tus microservicios de manera más efectiva.

En este módulo habilitas Istio en un único microservicio, `productpage`. El
resto de la aplicación continuará operando como antes. Ten en cuenta que
puedes habilitar Istio gradualmente, microservicio por microservicio. Istio se habilita
de manera transparente para los microservicios. No cambias el código de los microservicios ni
interrumpes tu aplicación, que continúa funcionando y atendiendo solicitudes de usuarios.

1.  Aplica las reglas de destino predeterminadas:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml
    {{< /text >}}

1.  Vuelve a desplegar el microservicio `productpage`, habilitado con Istio:

    {{< tip >}}
    Este paso del tutorial demuestra la inyección manual de sidecar para mostrar cómo habilitar Istio servicio por servicio con fines educativos.
    [La inyección automática de sidecar](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) es el método recomendado para uso en producción.
    {{< /tip >}}

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | sed 's/replicas: 1/replicas: 3/g' | kubectl apply -l app=productpage,version=v1 -f -
    deployment.apps/productpage-v1 configured
    {{< /text >}}

1.  Accede a la página web de la aplicación y verifica que la aplicación continúa
    funcionando. Istio se agregó sin cambiar el código de la
    aplicación original.

1.  Revisa los pods de `productpage` y observa que ahora cada réplica tiene dos contenedores.
    El primer contenedor es el propio microservicio y el segundo
    es el proxy sidecar adjunto a él:

    {{< text bash >}}
    $ kubectl get pods
    details-v1-68868454f5-8nbjv       1/1       Running   0          7h
    details-v1-68868454f5-nmngq       1/1       Running   0          7h
    details-v1-68868454f5-zmj7j       1/1       Running   0          7h
    productpage-v1-6dcdf77948-6tcbf   2/2       Running   0          7h
    productpage-v1-6dcdf77948-t9t97   2/2       Running   0          7h
    productpage-v1-6dcdf77948-tjq5d   2/2       Running   0          7h
    ratings-v1-76f4c9765f-khlvv       1/1       Running   0          7h
    ratings-v1-76f4c9765f-ntvkx       1/1       Running   0          7h
    ratings-v1-76f4c9765f-zd5mp       1/1       Running   0          7h
    reviews-v2-56f6855586-cnrjp       1/1       Running   0          7h
    reviews-v2-56f6855586-lxc49       1/1       Running   0          7h
    reviews-v2-56f6855586-qh84k       1/1       Running   0          7h
    curl-88ddbcfdd-cc85s              1/1       Running   0          7h
    {{< /text >}}

1.  Kubernetes reemplazó los pods originales de `productpage` con los
    pods habilitados con Istio, de manera transparente e incremental, realizando una
    [actualización continua](https://kubernetes.io/docs/tutorials/kubernetes-basics/update-intro/).
    Kubernetes terminó un pod antiguo solo cuando un nuevo pod comenzó a ejecutarse, y
    cambió el tráfico de manera transparente a los nuevos pods, uno por uno. Es decir, no
    terminó más de un pod antes de iniciar un nuevo pod. Todo esto se hizo para evitar
    interrupciones en tu aplicación, por lo que continuó funcionando durante la inyección de Istio.

1.  Revisa los registros del sidecar de Istio de `productpage`:

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy | grep GET
    ...
    [2019-02-15T09:06:04.079Z] "GET /details/0 HTTP/1.1" 200 - 0 178 5 3 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "details:9080" "172.30.230.51:9080" outbound|9080||details.tutorial.svc.cluster.local - 172.21.109.216:9080 172.30.146.104:58698 -
    [2019-02-15T09:06:04.088Z] "GET /reviews/0 HTTP/1.1" 200 - 0 379 22 22 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "reviews:9080" "172.30.230.27:9080" outbound|9080||reviews.tutorial.svc.cluster.local - 172.21.185.48:9080 172.30.146.104:41442 -
    [2019-02-15T09:06:04.053Z] "GET /productpage HTTP/1.1" 200 - 0 5723 90 83 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.146.104:9080 10.127.220.66:0 -
    {{< /text >}}

1.  Muestra el nombre de tu namespace. Lo necesitarás para reconocer tus
    microservicios en el tablero de Istio:

    {{< text bash >}}
    $ echo $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    tutorial
    {{< /text >}}

1.  Revisa el tablero de Istio, usando la URL personalizada que configuraste en tu archivo `/etc/hosts`
    [anteriormente](/es/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file):

    {{< text plain >}}
    http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
    {{< /text >}}

    En el menú desplegable superior izquierdo, selecciona _Istio Mesh Dashboard_.

    {{< image width="80%"
        link="dashboard-select-dashboard.png"
        caption="Selecciona Istio Mesh Dashboard desde el menú desplegable superior izquierdo"
        >}}

    Observa el servicio `productpage` de tu espacio de nombres, su nombre debería ser
    `productpage.<tu espacio de nombres>.svc.cluster.local`.

    {{< image width="80%"
        link="dashboard-mesh.png"
        caption="Istio Mesh Dashboard"
        >}}

1.  En el _Istio Mesh Dashboard_, en la columna `Service`, haz clic en el servicio `productpage`.

    {{< image width="80%"
        link="dashboard-service-select-productpage.png"
        caption="Tablero de servicio de Istio, `productpage` seleccionado"
        >}}

    Desplázate hacia abajo hasta la sección _Service Workloads_. Observa que los
    gráficos del tablero se actualizan.

    {{< image width="80%"
        link="dashboard-service.png"
        caption="Tablero de servicio de Istio"
        >}}

Este es el beneficio inmediato de aplicar Istio en un único microservicio. Recibes registros del tráfico hacia y desde el microservicio, incluyendo tiempo, método HTTP, ruta y código de respuesta. Puedes monitorear tu microservicio usando el tablero de Istio.

En los próximos módulos, aprenderás sobre la funcionalidad que Istio puede proporcionar a
tus aplicaciones. Aunque algunas funcionalidades de Istio son beneficiosas cuando se aplican a
un único microservicio, aprenderás cómo aplicar Istio en toda la
aplicación para aprovechar su máximo potencial.

Estás listo para
[habilitar Istio en todos los microservicios](/es/docs/examples/microservices-istio/enable-istio-all-microservices).
