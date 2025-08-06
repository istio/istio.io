---
title: Configurar un Cluster de Kubernetes
overview: Configurar tu Cluster de Kubernetes para el tutorial.
weight: 2
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

En este módulo, configuras un Cluster de Kubernetes que tiene Istio instalado y un
namespace para usar durante todo el tutorial.

{{< warning >}}
Si estás en un taller y los instructores proporcionan un cluster para ti,
procede a [configurar tu computadora local](/es/docs/examples/microservices-istio/setup-local-computer).
{{</ warning >}}

1.  Asegúrate de tener acceso a un
    [Cluster de Kubernetes](https://kubernetes.io/docs/tutorials/kubernetes-basics/).
    Puedes usar el
    [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/quickstart)
    o el
    [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started).

1.  Crea una variable de entorno para almacenar el nombre
    de un namespace que usarás cuando ejecutes los comandos del tutorial.
    Puedes usar cualquier nombre, por ejemplo `tutorial`.

    {{< text bash >}}
    $ export NAMESPACE=tutorial
    {{< /text >}}

1.  Crea el namespace:

    {{< text bash >}}
    $ kubectl create namespace $NAMESPACE
    {{< /text >}}

    {{< tip >}}
    Si eres instructor, deberías asignar un namespace separado por cada
    participante. El tutorial soporta trabajo en múltiples namespaces
    simultáneamente por múltiples participantes.
    {{< /tip >}}

1.  [Instala Istio](/es/docs/setup/getting-started/) usando el perfil `demo`.

1.  Los addons [Kiali](/es/docs/ops/integrations/kiali/) y [Prometheus](/es/docs/ops/integrations/prometheus/) se usan en este ejemplo y necesitan ser instalados. Todos los addons se instalan usando:

    {{< text bash >}}
    $ kubectl apply -f @samples/addons@
    {{< /text >}}

    {{< tip >}}
    Si hay errores tratando de instalar los addons, intenta ejecutar el comando nuevamente. Puede que
    haya algunos problemas de temporización que se resolverán cuando el comando se ejecute nuevamente.
    {{< /tip >}}

1.  Crea un recurso Kubernetes Ingress para estos servicios comunes de Istio usando
    el comando `kubectl` mostrado. No es necesario estar familiarizado con cada uno de
    estos servicios en este punto del tutorial.

    - [Grafana](https://grafana.com/docs/guides/getting_started/)
    - [Jaeger](https://www.jaegertracing.io/docs/1.13/getting-started/)
    - [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
    - [Kiali](https://kiali.io/docs/installation/quick-start/)

    El comando `kubectl` puede aceptar una configuración en línea para crear los
    recursos Ingress para cada servicio:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: istio-system
      namespace: istio-system
      annotations:
        kubernetes.io/ingress.class: istio
    spec:
      rules:
      - host: my-istio-dashboard.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
      - host: my-istio-tracing.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tracing
                port:
                  number: 9411
      - host: my-istio-logs-database.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus
                port:
                  number: 9090
      - host: my-kiali.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kiali
                port:
                  number: 20001
    EOF
    {{< /text >}}

1.  Crea un rol para proporcionar acceso de lectura al namespace `istio-system`. Este
    rol es requerido para limitar los permisos de los participantes en los pasos
    a continuación.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-system-access
      namespace: istio-system
    rules:
    - apiGroups: ["", "extensions", "apps"]
      resources: ["*"]
      verbs: ["get", "list"]
    EOF
    {{< /text >}}

1.  Crea una service account para cada participante:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    EOF
    {{< /text >}}

1.  Limita los permisos de cada participante. Durante el tutorial, los participantes solo
    necesitan crear recursos en su namespace y leer recursos del
    namespace `istio-system`. Es una buena práctica, incluso si usas tu propio
    cluster, evitar interferir con otros namespaces en
    tu cluster.

    Crea un rol para permitir acceso de lectura-escritura al namespace de cada participante.
    Vincula la cuenta de servicio del participante a este rol y al rol para
    leer recursos desde `istio-system`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    rules:
    - apiGroups: ["", "extensions", "apps", "networking.k8s.io", "networking.istio.io", "authentication.istio.io",
                  "rbac.istio.io", "config.istio.io", "security.istio.io"]
      resources: ["*"]
      verbs: ["*"]
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: ${NAMESPACE}-access
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-istio-system-access
      namespace: istio-system
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: istio-system-access
    EOF
    {{< /text >}}

1.  Cada participante necesita usar su propio archivo de configuración de Kubernetes. Este archivo de configuración especifica
    los detalles del cluster, la service account, las credenciales y el namespace del participante.
    El comando `kubectl` usa el archivo de configuración para operar en el cluster.

    Genera un archivo de configuración de Kubernetes para cada participante:

    {{< tip >}}
    Este comando asume que tu cluster se llama `tutorial-cluster`. Si tu cluster tiene un nombre diferente, reemplaza todas las referencias con el nombre de tu cluster.
    {{</ tip >}}

    {{< text bash >}}
    $ cat <<EOF > ./${NAMESPACE}-user-config.yaml
    apiVersion: v1
    kind: Config
    preferences: {}

    clusters:
    - cluster:
        certificate-authority-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        server: $(kubectl config view -o jsonpath="{.clusters[?(.name==\"$(kubectl config view -o jsonpath="{.contexts[?(.name==\"$(kubectl config current-context)\")].context.cluster}")\")].cluster.server}")
      name: ${NAMESPACE}-cluster

    users:
    - name: ${NAMESPACE}-user
      user:
        as-user-extra: {}
        client-key-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        token: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath={.data.token} | base64 --decode)

    contexts:
    - context:
        cluster: ${NAMESPACE}-cluster
        namespace: ${NAMESPACE}
        user: ${NAMESPACE}-user
      name: ${NAMESPACE}

    current-context: ${NAMESPACE}
    EOF
    {{< /text >}}

1.  Establece la variable de entorno `KUBECONFIG` para el archivo de configuración
    `${NAMESPACE}-user-config.yaml`:

    {{< text bash >}}
    $ export KUBECONFIG=$PWD/${NAMESPACE}-user-config.yaml
    {{< /text >}}

1.  Verifica que la configuración surtió efecto imprimiendo el namespace actual:

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    Deberías ver el nombre de tu namespace en la salida.

1.  Si estás configurando el cluster para ti mismo, copia el
    archivo `${NAMESPACE}-user-config.yaml` mencionado en los pasos anteriores a tu
    computadora local, donde `${NAMESPACE}` es el nombre del namespace que
    proporcionaste en los pasos anteriores. Por ejemplo, `tutorial-user-config.yaml`.
    Necesitarás este archivo más tarde en el tutorial.

    Si eres instructor, envía los archivos de configuración generados a cada
    participante. Los participantes deben copiar su archivo de configuración a su computadora local.

¡Felicidades, configuraste tu cluster para el tutorial!

Estás listo para [configurar una computadora local](/es/docs/examples/microservices-istio/setup-local-computer).
