---
title: Egress TLS Origination
description: Describes how to configure Istio to perform TLS origination for traffic to external services.
keywords: [traffic-management,egress]
weight: 20
owner: istio/wg-networking-maintainers
test: yes
aliases:
  - /docs/examples/advanced-gateways/egress-tls-origination/
---

The [Accessing External Services](/docs/tasks/traffic-management/egress/egress-control) task demonstrates how external,
i.e., outside of the service mesh, HTTP and HTTPS services can be accessed from applications inside the mesh. As described
in that task, a [`ServiceEntry`](/docs/reference/config/networking/service-entry/) is used to configure Istio
to access external services in a controlled way.
This example shows how to configure Istio to perform {{< gloss >}}TLS origination{{< /gloss >}}
for traffic to an external service. Istio will open HTTPS connections to the external service while the original
traffic is HTTP.

## Use case

Consider a legacy application that performs HTTP calls to external sites. Suppose the organization that operates the
application receives a new requirement which states that all the external traffic must be encrypted. With Istio,
this requirement can be achieved just by configuration, without changing any code in the application.
The application can send unencrypted HTTP requests and Istio will then encrypt them for the application.

Another benefit of sending unencrypted HTTP requests from the source, and letting Istio perform the TLS upgrade,
is that Istio can produce better telemetry and provide more routing control for requests that are not encrypted.

## Before you begin

* Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Start the [sleep]({{< github_tree >}}/samples/sleep) sample which will be used as a test source for external calls.

    If you have enabled [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), deploy the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    Otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    Note that any pod that you can `exec` and `curl` from will do for the procedures below.

*   Create a shell variable to hold the name of the source pod for sending requests to external services.
    If you used the [sleep]({{< github_tree >}}/samples/sleep) sample, run:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Configuring access to an external service

First start by configuring access to an external service, `edition.cnn.com`,
using the same technique shown in the [Accessing External Services](/docs/tasks/traffic-management/egress/egress-control) task.
This time, however, use a single `ServiceEntry` to enable both HTTP and HTTPS access to the service.

1.  Create a `ServiceEntry` to enable access to `edition.cnn.com`:

    {{< text syntax=bash snip_id=apply_simple >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Make a request to the external HTTP service:

    {{< text syntax=bash snip_id=curl_simple >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    ...
    {{< /text >}}

    The output should be similar to the above (some details replaced by ellipsis).

Notice the `-L` flag of _curl_ which instructs _curl_ to follow redirects.
In this case, the server returned a redirect response ([301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2))
for the HTTP request to `http://edition.cnn.com/politics`.
The redirect response instructs the client to send an additional request, this time using HTTPS, to `https://edition.cnn.com/politics`.
For the second request, the server returned the requested content and a _200 OK_ status code.

Although the _curl_ command handled the redirection transparently, there are two issues here.
The first issue is the redundant request, which doubles the latency of fetching the content of `http://edition.cnn.com/politics`.
The second issue is that the path of the URL, _politics_ in this case, is sent in clear text.
If there is an attacker who sniffs the communication between your application and `edition.cnn.com`,
the attacker would know which specific topics of `edition.cnn.com` the application fetched.
For privacy reasons, you might want to prevent such disclosure.

Both of these issues can be resolved by configuring Istio to perform TLS origination.

## TLS origination for egress traffic

1.  Redefine your `ServiceEntry` from the previous section to redirect HTTP requests to port 443
    and add a `DestinationRule` to perform TLS origination:

    {{< text syntax=bash snip_id=apply_origination >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
        targetPort: 443
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        portLevelSettings:
        - port:
            number: 80
          tls:
            mode: SIMPLE # initiates HTTPS when accessing edition.cnn.com
    EOF
    {{< /text >}}

    The above `DestinationRule` will perform TLS origination for HTTP requests on port 80 and the `ServiceEntry`
    will then redirect the requests on port 80 to target port 443.

1. Send an HTTP request to `http://edition.cnn.com/politics`, as in the previous section:

    {{< text syntax=bash snip_id=curl_origination_http >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    This time you receive _200 OK_ as the first and the only response. Istio performed TLS origination for _curl_ so
    the original HTTP request was forwarded to `edition.cnn.com` as HTTPS. The server returned the content directly,
    without the need for redirection. You eliminated the double round trip between the client and the server, and the
    request left the mesh encrypted, without disclosing the fact that your application fetched the _politics_ section
    of `edition.cnn.com`.

    Note that you used the same command as in the previous section. For applications that access external services
    programmatically, the code does not need to be changed. You get the benefits of TLS origination by configuring Istio,
    without changing a line of code.

1.  Note that the applications that used HTTPS to access the external service continue to work as before:

    {{< text syntax=bash snip_id=curl_origination_https >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/2 200
    ...
    {{< /text >}}

## Additional security considerations

Because the traffic between the application pod and the sidecar proxy on the local host is still unencrypted,
an attacker that is able to penetrate the node of your application would still be able to see the unencrypted
communication on the local network of the node. In some environments a strict security requirement
might state that all the traffic must be encrypted, even on the local network of the nodes.
With such a strict requirement, applications should use HTTPS (TLS) only. The TLS origination described in this
example would not be sufficient.

Also note that even with HTTPS originated by the application, an attacker could know that requests to `edition.cnn.com`
are being sent by inspecting [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication).
The _SNI_ field is sent unencrypted during the TLS handshake. Using HTTPS prevents the attackers from knowing specific
topics and articles but does not prevent attackers from learning that `edition.cnn.com` is accessed.

### Cleanup the TLS origination configuration

Remove the Istio configuration items you created:

{{< text bash >}}
$ kubectl delete serviceentry edition-cnn-com
$ kubectl delete destinationrule edition-cnn-com
{{< /text >}}

## Mutual TLS origination for egress traffic

This section describes how to configure a sidecar to perform TLS origination for an external service, this time using a
service that requires mutual TLS. This example is considerably more involved because it requires the following setup:

1. Generate client and server certificates
1. Deploy an external service that supports the mutual TLS protocol
1. Configure the client (sleep pod) to use the credentials created in Step 1

Once this setup is complete, you can then configure the external traffic to go through the sidecar which will perform
TLS origination.

### Generate client and server certificates and keys

For this task you can use your favorite tool to generate certificates and keys. The commands below use
[openssl](https://man.openbsd.org/openssl.1)

1.  Create a root certificate and private key to sign the certificate for your services:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  Create a certificate and a private key for `my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

    Optionally, you can add `SubjectAltNames` to the certificate if you want to enable SAN validation for the destination. For example:

    {{< text syntax=bash snip_id=none >}}
    $ cat > san.conf <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    x509_extensions = v3_req
    prompt = no
    [req_distinguished_name]
    countryName = US
    [v3_req]
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    basicConstraints = critical, CA:FALSE
    subjectAltName = critical, @alt_names
    [alt_names]
    DNS = my-nginx.mesh-external.svc.cluster.local
    EOF
    $
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:4096 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization" -config san.conf
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt -extfile san.conf -extensions v3_req
    {{< /text >}}

1.  Generate client certificate and private key:

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### Deploy a mutual TLS server

To simulate an actual external service that supports the mutual TLS protocol,
deploy an [NGINX](https://www.nginx.com) server in your Kubernetes cluster, but running outside of
the Istio service mesh, i.e., in a namespace without Istio sidecar proxy injection enabled.

1.  Create a namespace to represent services outside the Istio mesh, namely `mesh-external`. Note that the sidecar proxy will
    not be automatically injected into the pods in this namespace since the automatic sidecar injection was not
    [enabled](/docs/setup/additional-setup/sidecar-injection/#deploying-an-app) on it.

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Create a configuration file for the NGINX server:

    {{< text bash >}}
    $ cat <<\EOF > ./nginx.conf
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
        ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the NGINX server:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  Deploy the NGINX server:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
      labels:
        run: my-nginx
      annotations:
        "networking.istio.io/exportTo": "." # simulate an external service by not exporting outside this namespace
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
            - containerPort: 443
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

### Configure the client (sleep pod)

1.  Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the client's certificates:

    {{< text bash >}}
    $ kubectl create secret generic client-credential --from-file=tls.key=client.example.com.key \
      --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
    {{< /text >}}

    The secret **must** be created in the same namespace as the client pod is deployed in, `default` in this case.

    {{< tip >}}
    {{< boilerplate crl-tip >}}
    {{< /tip >}}

1. Create required `RBAC` to make sure the secret created in the above step is accessible to the client pod, which is `sleep` in this case.

    {{< text bash >}}
    $ kubectl create role client-credential-role --resource=secret --verb=list
    $ kubectl create rolebinding client-credential-role-binding --role=client-credential-role --serviceaccount=default:sleep
    {{< /text >}}

### Configure mutual TLS origination for egress traffic at sidecar

1.  Add a `ServiceEntry` to redirect HTTP requests to port 443 and add a `DestinationRule` to perform mutual TLS origination:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: originate-mtls-for-nginx
    spec:
      hosts:
      - my-nginx.mesh-external.svc.cluster.local
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
        targetPort: 443
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: originate-mtls-for-nginx
    spec:
      workloadSelector:
        matchLabels:
          app: sleep
      host: my-nginx.mesh-external.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 80
          tls:
            mode: MUTUAL
            credentialName: client-credential # this must match the secret created earlier to hold client certs, and works only when DR has a workloadSelector
            sni: my-nginx.mesh-external.svc.cluster.local # this is optional
    EOF
    {{< /text >}}

    The above `DestinationRule` will perform mTLS origination for HTTP requests on port 80 and the `ServiceEntry`
    will then redirect the requests on port 80 to target port 443.

1.  Verify that the credential is supplied to the sidecar and active.

    {{< text bash >}}
    $ istioctl proxy-config secret deploy/sleep | grep client-credential
    kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:15:20Z     2023-06-05T12:15:20Z
    kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           10792363984292733914                       2024-06-04T12:15:19Z     2023-06-05T12:15:19Z
    {{< /text >}}

1.  Send an HTTP request to `http://my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  Check the log of the `sleep` pod for a line corresponding to our request.

    {{< text bash >}}
    $ kubectl logs -l app=sleep -c istio-proxy | grep 'my-nginx.mesh-external.svc.cluster.local'
    {{< /text >}}

    You should see a line similar to the following:

    {{< text plain>}}
    [2022-05-19T10:01:06.795Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 1 0 "-" "curl/7.83.1-DEV" "96e8d8a7-92ce-9939-aa47-9f5f530a69fb" "my-nginx.mesh-external.svc.cluster.local:443" "10.107.176.65:443"
    {{< /text >}}

### Cleanup the mutual TLS origination configuration

1.  Remove created Kubernetes resources:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret client-credential
    $ kubectl delete rolebinding client-credential-role-binding
    $ kubectl delete role client-credential-role
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    $ kubectl delete serviceentry originate-mtls-for-nginx
    $ kubectl delete destinationrule originate-mtls-for-nginx
    {{< /text >}}

1.  Delete the certificates and private keys:

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

1.  Delete the generated configuration files used in this example:

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}

## Cleanup common configuration

Delete the `sleep` service and deployment:

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
