---
title: Configure an Egress Gateway with mutual TLS
description: Describes how to configure an Egress Gateway to perform mutual TLS to external services
weight: 45
keywords: [traffic-management,egress]
---

The [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example describes how to configure
Istio to direct the egress traffic through a dedicated service called _Egress Gateway_. This examples shows how to
configure an Egress Gateway to perform mutual TLS to external services.
You will deploy an [NGINX](https://www.nginx.com/) server in your Kubernetes cluster without injecting Istio sidecar
proxy into it.
This server will simulate a server outside the Istio service mesh. Then you will configure the Egress Gateway to
perform mutual TLS with this server.
Finally, you will direct the traffic from the application pods inside the mesh to the server outside the mesh through
the Egress Gateway. The Egress Gateway will perform mutual TLS origination with the NGINX server.

## Before you begin

This examples assumes you deployed Istio with [mutual TLS Authentication](/docs/tasks/security/mutual-tls/)
enabled. Follow the steps in the [Before you begin](/docs/examples/advanced-egress/egress-gateway/#before-you-begin)
section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

## Generate client and server certificates and keys

Generate the certificates and keys in the same way as in the [Securing Gateways with HTTPS](docs/tasks/traffic-management/secure-ingress/#generate-client-and-server-certificates-and-keys).

1.  Clone the <https://github.com/nicholasjackson/mtls-go-example> repository:

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  Change directory to the cloned repository:

    {{< text bash >}}
    $ pushd mtls-go-example
    {{< /text >}}

1.  Generate the certificates for `my-nginx.mesh-external.svc.cluster.local`.
    Use any password with the following command:

    {{< text bash >}}
    $ ./generate.sh my-nginx.mesh-external.svc.cluster.local <password>
    {{< /text >}}

    When prompted, select `y` for all the questions.

1.  Move the certificates into `my-nginx.mesh-external.svc.cluster.local` directory:

    {{< text bash >}}
    $ mkdir ~+1/my-nginx.mesh-external.svc.cluster.local && mv 1_root 2_intermediate 3_application 4_client ~+1/my-nginx.mesh-external.svc.cluster.local
    {{< /text >}}

1.  Change directory back:

    {{< text bash >}}
    $ popd
    {{< /text >}}

## Deploy an Nginx server

1.  Create a namespace `mesh-external` to represent services outside the Istio mesh. Note that the sidecar proxy will
    not be automatically injected into the pods in this namespace since the automatic sidecar injection was not
    [enabled](/docs/setup/kubernetes/sidecar-injection/#deploying-an-app) on it.

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local/3_application/private/my-nginx.mesh-external.svc.cluster.local.key.pem --cert my-nginx.mesh-external.svc.cluster.local/3_application/certs/my-nginx.mesh-external.svc.cluster.local.cert.pem
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=my-nginx.mesh-external.svc.cluster.local/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  Create a configuration file for the NGINX server:

    {{< text bash >}}
    $ cat <<EOF > ./nginx.conf
    events {
    }

    http {
      log_format main '$remote_addr - $remote_user [$time_local]  $status '
      '"$request" $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name my-nginx.mesh-external.svc.cluster.local;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
        ssl_client_certificate /etc/nginx-ca-certs/ca-chain.cert.pem;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the Nginx SNI proxy:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  Deploy the NGINX server:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
      labels:
        run: my-nginx
    spec:
      ports:
      - port: 80
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
      namespace: mesh-external
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
        spec:
          containers:
          - name: my-nginx
            image: nginx
            ports:
            - containerPort: 80
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

##  Redeploy the Egress Gateway with the client certificates

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the client's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls nginx-client-certs --key my-nginx.mesh-external.svc.cluster.local/4_client/private/my-nginx.mesh-external.svc.cluster.local.key.pem --cert my-nginx.mesh-external.svc.cluster.local/4_client/certs/my-nginx.mesh-external.svc.cluster.local.cert.pem
    $ kubectl create -n istio-system secret generic nginx-ca-certs --from-file=my-nginx.mesh-external.svc.cluster.local/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  Generate the `istio-egressgateway` deployment with a volume to be mounted from the new secrets. Use the same options
    you used for generating your `istio.yaml`:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio-egressgateway --namespace istio-system -x charts/gateways/templates/deployment.yaml --set gateways.istio-ingressgateway.enabled=false \
    --set gateways.istio-egressgateway.secretVolumes[0].name=egressgateway-certs \
    --set gateways.istio-egressgateway.secretVolumes[0].secretName=istio-egressgateway-certs \
    --set gateways.istio-egressgateway.secretVolumes[0].mountPath=/etc/istio/egressgateway-certs \
    --set gateways.istio-egressgateway.secretVolumes[1].name=egressgateway-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[1].secretName=istio-egressgateway-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[1].mountPath=/etc/istio/egressgateway-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[2].name=nginx-client-certs \
    --set gateways.istio-egressgateway.secretVolumes[2].secretName=nginx-client-certs \
    --set gateways.istio-egressgateway.secretVolumes[2].mountPath=/etc/nginx-client-certs \
    --set gateways.istio-egressgateway.secretVolumes[3].name=nginx-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[3].secretName=nginx-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[3].mountPath=/etc/nginx-ca-certs > \
    ./istio-egressgateway.yaml
    {{< /text >}}

1.  Redeploy `istio-egressgateway`:

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway.yaml
    deployment "istio-egressgateway" configured
    {{< /text >}}

1.  Verify that the key and the certificate are successfully loaded in the `istio-egressgateway` pod:

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=egressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/nginx-client-certs /etc/nginx-ca-certs
    {{< /text >}}

    `tls.crt` and `tls.key` should exist in `/etc/istio/nginx-client-certs`, while `ca-chain.cert.pem` in
    `/etc/istio/nginx-ca-certs`.

##  Cleanup

1.  Perform the instructions in the [Cleanup](/docs/examples/advanced-egress/egress-gateway/#cleanup)
    section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

1.  Remove created Kubernetes resources:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret nginx-client-certs nginx-ca-certs -n istio-system
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    {{< /text >}}

1.  Delete the directory of the certificates and the repository used to generate them:

    {{< text bash >}}
    $ rm -rf my-nginx.mesh-external.svc.cluster.local mtls-go-example
    {{< /text >}}

1.  Delete the generated configuration files used in this example:

    {{< text bash >}}
    $ rm -f ./nginx.conf ./istio-egressgateway.yaml
    {{< /text >}}
