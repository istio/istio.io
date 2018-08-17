---
title: Ingress Gateway for an HTTPS service
description: Describes how to configure an Ingress Gateway for an HTTPS service.
weight: 31
keywords: [traffic-management,ingress, https]
---

The [Securing Gateways with HTTPS](/docs/tasks/traffic-management/secure-ingress/) task describes how to configure HTTPS
ingress access to an HTTP service. This example describes how to configure ingress access to an HTTPS service.

## Generate client and server certificates and keys

Generate the certificates and keys in the same way as in the [Securing Gateways with HTTPS](/docs/tasks/traffic-management/secure-ingress/#generate-client-and-server-certificates-and-keys).

1.  Clone the <https://github.com/nicholasjackson/mtls-go-example> repository:

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  Change directory to the cloned repository:

    {{< text bash >}}
    $ pushd mtls-go-example
    {{< /text >}}

1.  Generate the certificates for `nginx.example.com`.
    Use any password with the following command:

    {{< text bash >}}
    $ ./generate.sh nginx.example.com <password>
    {{< /text >}}

    When prompted, select `y` for all the questions.

1.  Move the certificates into `nginx.example.com` directory:

    {{< text bash >}}
    $ mkdir ~+1/nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ~+1/nginx.example.com
    {{< /text >}}

1.  Change directory back:

    {{< text bash >}}
    $ popd
    {{< /text >}}

## Deploy an NGINX server

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's
   certificate.

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
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

        server_name nginx.example.com;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the NGINX:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap  --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  Deploy the NGINX server:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      labels:
        run: my-nginx
    spec:
      ports:
      - port: 443
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
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
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
    EOF
    {{< /text >}}

### Test the NGINX deployment

1.  Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the CA certificate:

    {{< text bash >}}
    $ kubectl create secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample with mounted client and CA certificates to test sending
    requests to the NGINX server:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply  -f -
    # Copyright 2017 Istio Authors
    #
    #   Licensed under the Apache License, Version 2.0 (the "License");
    #   you may not use this file except in compliance with the License.
    #   You may obtain a copy of the License at
    #
    #       http://www.apache.org/licenses/LICENSE-2.0
    #
    #   Unless required by applicable law or agreed to in writing, software
    #   distributed under the License is distributed on an "AS IS" BASIS,
    #   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #   See the License for the specific language governing permissions and
    #   limitations under the License.

    ##################################################################################################
    # Sleep service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: sleep
      labels:
        app: sleep
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: sleep
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: sleep
        spec:
          containers:
          - name: sleep
            image: tutum/curl
            command: ["/bin/sleep","infinity"]
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

1.  Use the deployed [sleep]({{< github_tree >}}/samples/sleep) container to send requests to the NGINX server:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod  -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -v --cacert /etc/nginx-ca-certs/ca-chain.cert.pem https://nginx.example.com
    ...
    Server certificate:
      subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=nginx.example.com
      start date: 2018-08-16 04:31:20 GMT
      expire date: 2019-08-26 04:31:20 GMT
      common name: nginx.example.com (matched)
      issuer: C=US; ST=Denial; O=Dis; CN=nginx.example.com
      SSL certificate verify ok.
    > GET / HTTP/1.1
    > User-Agent: curl/7.35.0
    > Host: nginx.example.com
    ...
    < HTTP/1.1 200 OK

    < Server: nginx/1.15.2
    ...
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  Cleanup:

    {{< text bash >}}
    $ kubectl delete  service sleep
    $ kubectl delete  deployment sleep
    $ kubectl delete  secret nginx-ca-certs
    {{< /text >}}

## Cleanup

1.  Remove created Kubernetes resources:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs
    $ kubectl delete configmap nginx-configmap
    $ kubectl delete service my-nginx
    $ kubectl delete deployment my-nginx
    {{< /text >}}

1.  Delete the directory of the certificates and the repository used to generate them:

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1.  Delete the generated configuration files used in this example:

    {{< text bash >}}
    $ rm -f ./nginx.conf
    {{< /text >}}
