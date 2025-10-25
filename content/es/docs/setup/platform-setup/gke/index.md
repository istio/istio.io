---
title: Google Kubernetes Engine
description: Instrucciones para configurar un cluster de Google Kubernetes Engine para Istio.
weight: 20
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/gke/
    - /docs/setup/kubernetes/platform-setup/gke/
keywords: [platform-setup,kubernetes,gke,google]
owner: istio/wg-environments-maintainers
test: no
---

Sigue estas instrucciones para preparar un cluster de GKE para Istio.

1. Crea un nuevo cluster.

    {{< text bash >}}
    $ export PROJECT_ID=`gcloud config get-value project` && \
      export M_TYPE=n1-standard-2 && \
      export ZONE=us-west2-a && \
      export CLUSTER_NAME=${PROJECT_ID}-${RANDOM} && \
      gcloud services enable container.googleapis.com && \
      gcloud container clusters create $CLUSTER_NAME \
      --cluster-version latest \
      --machine-type=$M_TYPE \
      --num-nodes 4 \
      --zone $ZONE \
      --project $PROJECT_ID
    {{< /text >}}

    {{< tip >}}
    La instalación predeterminada de Istio requiere nodos con >1 vCPU. Si estás
    instalando con el
    [perfil de configuración demo](/es/docs/setup/additional-setup/config-profiles/),
    puedes eliminar el argumento `--machine-type` para usar el tamaño de máquina más pequeño `n1-standard-1` en su lugar.
    {{< /tip >}}

    {{< warning >}}
    Para usar la característica CNI de Istio en GKE Standard, por favor revisa la [guía de instalación CNI](/es/docs/setup/additional-setup/cni/#prerequisites)
    para los pasos de configuración de prerequisitos del cluster. Dado que el agente de nodo CNI requiere la capacidad SYS_ADMIN, no está disponible en GKE Autopilot. En su lugar, usa el contenedor istio-init.
    {{< /warning >}}

    {{< warning >}}
    **Para clusters GKE privados**

    Una regla de firewall creada automáticamente no abre el puerto 15017. Esto es necesario para el webhook de validación de descubrimiento de istiod.

    Para revisar esta regla de firewall para acceso del master:

    {{< text bash >}}
    $ gcloud compute firewall-rules list --filter="name~gke-${CLUSTER_NAME}-[0-9a-z]*-master"
    {{< /text >}}

    Para reemplazar la regla existente y permitir el acceso del master:

    {{< text bash >}}
    $ gcloud compute firewall-rules update <firewall-rule-name> --allow tcp:10250,tcp:443,tcp:15017
    {{< /text >}}

    {{< /warning >}}

1. Recupera tus credenciales para `kubectl`.

    {{< text bash >}}
    $ gcloud container clusters get-credentials $CLUSTER_NAME \
        --zone $ZONE \
        --project $PROJECT_ID
    {{< /text >}}

1. Otorga permisos de administrador de clúster (admin) al usuario actual. Para
   crear las reglas RBAC necesarias para Istio, el usuario actual requiere permisos de administrador.

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}

## Comunicación entre clústeres múltiples

En algunos casos, es necesario crear una regla de firewall explícita para permitir el tráfico entre clústeres.

{{< warning >}}
Las siguientes instrucciones permitirán la comunicación entre *todos* los clústeres en tu proyecto. Ajusta los comandos según sea necesario.
{{< /warning >}}

1. Recopila información sobre la red de tus clústeres.

    {{< text bash >}}
    $ function join_by { local IFS="$1"; shift; echo "$*"; }
    $ ALL_CLUSTER_CIDRS=$(gcloud --project $PROJECT_ID container clusters list --format='value(clusterIpv4Cidr)' | sort | uniq)
    $ ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}"))
    $ ALL_CLUSTER_NETTAGS=$(gcloud --project $PROJECT_ID compute instances list --format='value(tags.items.[0])' | sort | uniq)
    $ ALL_CLUSTER_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))
    {{< /text >}}

1. Crea la regla de firewall.

    {{< text bash >}}
    $ gcloud compute firewall-rules create istio-multicluster-pods \
        --allow=tcp,udp,icmp,esp,ah,sctp \
        --direction=INGRESS \
        --priority=900 \
        --source-ranges="${ALL_CLUSTER_CIDRS}" \
        --target-tags="${ALL_CLUSTER_NETTAGS}" --quiet
    {{< /text >}}
