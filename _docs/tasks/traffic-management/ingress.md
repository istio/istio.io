---
title: Istio Ingress Controller
overview: Describes how to configure the Istio ingress controller on Kubernetes.

order: 30

layout: docs
type: markdown
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster.
In a Kubernetes environment, the [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/)
allows users to specify services that should be exposed outside the
cluster. However, the Ingress Resource specification is very minimal,
allowing users to specify just hosts, paths and their backing services.
To take advantage of Istio's advanced routing capabilities, we recommend
combining a minimal Ingress Resource specification with Istio's route
rules.

> Note: Istio does not support `ingress.kubernetes.io` annotations in the ingress resource
> specifications. Any annotation other than `kubernetes.io/ingress.class: istio` will be ignored.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).
  
* Make sure your current directory is the `istio` directory.
  
* Start the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) sample,
  which will be used as the destination service to be exposed externally.

  If you installed the [Istio-Initializer]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection), do

  ```bash
  kubectl apply -f samples/httpbin/httpbin.yaml
  ```

  Without the Istio-Initializer:

  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
  ```

## Configuring ingress (HTTP)

1. Create a basic Ingress Resource for the httpbin service

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: simple-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     rules:
     - http:
         paths:
         - path: /.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```
 
   `/.*` is a special Istio notation that is used to indicate a prefix
   match, specifically a configuration of the form (`prefix: /`). This
   configuration above will allow access to all URIs in the httpbin
   service. However we wish to enable access only to specific URIs under the
   httpbin service. Let us define a default _deny all_ route rule that
   provides this behavior:

   ```bash
   cat <<EOF | istioctl create -f -
   ## Deny all access from istio-ingress
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: deny-route
   spec:
     destination:
       name: httpbin
     match:
       # Limit this rule to istio ingress pods only
       source:
         name: istio-ingress
         labels:
           istio: ingress
     precedence: 1
     route:
     - weight: 100
     httpFault:
       abort:
         percent: 100
         httpStatus: 403 #Forbidden for all URLs
   EOF
   ```   
2. Now, allow requests to `/status/` prefix by defining a route rule of
   higher priority.

   ```bash
   cat <<EOF | istioctl create -f -
   ## Allow requests to /status prefix
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: status-route
   spec:
     destination:
       name: httpbin
     match:
       # Limit this rule to istio ingress pods only
       source:
         name: istio-ingress
         labels:
           istio: ingress
       request:
         headers:
           uri:
             prefix: /status
     precedence: 2 #must be higher precedence than the deny-route
     route:
     - weight: 100
   EOF
   ```
  You can use other features of the route rules such as redirects,
  rewrites, regular expression based match in HTTP headers, websocket
  upgrades, timeouts, retries, and so on. Please refer to the
  [routing rules]({{home}}/docs/reference/config/traffic-rules/routing-rules.html)
  for more details.

## Verifying ingress

1. Determine the ingress URL:

   * If your cluster is running in an environment that supports external load balancers,
     use the ingress' external address:

     ```bash
     kubectl get ingress simple-ingress -o wide
     ```
   
     ```bash
     NAME             HOSTS     ADDRESS                 PORTS     AGE
     simple-ingress   *         130.211.10.121          80        1d
     ```

     ```bash
     export INGRESS_HOST=130.211.10.121
     ```

   * If load balancers are not supported, use the ingress controller pod's hostIP:
   
     ```bash
     kubectl -n istio-system get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'
     ```

     ```bash
     169.47.243.100
     ```

     along with the istio-ingress service's nodePort for port 80:
   
     ```bash
     kubectl -n istio-system get svc istio-ingress
     ```
   
     ```bash
     NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
     istio-ingress   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
     ```
   
     ```bash
     export INGRESS_HOST=169.47.243.100:31486
     ```
   
1. Access the httpbin service using _curl_:

   ```bash
   curl -I http://$INGRESS_HOST/status/200
   ```

   ```bash
   HTTP/1.1 200 OK
   Server: meinheld/0.6.1
   Date: Thu, 05 Oct 2017 21:23:17 GMT
   Content-Type: text/html; charset=utf-8
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Credentials: true
   X-Powered-By: Flask
   X-Processed-Time: 0.00105214118958
   Content-Length: 0
   Via: 1.1 vegur
   Connection: Keep-Alive
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 403

   ```bash
   curl -I http://$INGRESS_HOST/headers
   ```

   ```bash
   HTTP/1.1 403 FORBIDDEN
   Server: meinheld/0.6.1
   Date: Thu, 05 Oct 2017 21:24:47 GMT
   Content-Type: text/html; charset=utf-8
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Credentials: true
   X-Powered-By: Flask
   X-Processed-Time: 0.000759840011597
   Content-Length: 0
   Via: 1.1 vegur
   Connection: Keep-Alive
   ```

## Configuring secure ingress (HTTPS)

1. Generate keys if necessary

   A private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=foo.bar.com"
   ```

1. Update the secret using `kubectl`

   ```bash
   kubectl create -n istio-system secret tls istio-ingress-certs --key /tmp/tls.key --cert /tmp/tls.crt
   ```

1. Create the Ingress Resource for the httpbin service

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: secure-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     tls:
       - secretName: istio-ingress-certs # currently ignored
     rules:
     - http:
         paths:
         - path: /.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

   Create the _deny rule_ and the rule for `/status` prefix as described
   earlier. Set the INGRESS_HOST to point to the ip address and the
   port number of the ingress service as shown earlier.

   > Note: Envoy currently only allows a single TLS secret in the ingress since SNI is not yet supported. That means that the secret name field in ingress resource is not used, and the secret must be called `istio-ingress-certs` in `istio-system` namespace.

    
1. Access the secured httpbin service using _curl_:

   ```bash
   curl -I -k https://$INGRESS_HOST/status/200
   ```

## Configuring RBAC for ingress key/cert
There are service accounts which can access this ingress key/cert, and the ingress key/cert is not 
encrypted. This leads to risks of leaking key/cert. We can set up Role-Based Access Control ("RBAC") 
to protect the ingress key/cert. [istio/install/kubernetes/istio.yaml](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml) 
defines some ClusterRoles which grant access to all secret resources. For example, 
istio-pilot-istio-system and istio-mixer-istio-system allow reading secret resources, and 
istio-ca-istio-system allows reading, creating and updating secret resources.
[istio/install/kubernetes/istio.yaml](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml) 
also defines ClusterRoleBindings which bind these ClusterRoles to service accounts, for example, 
istio-pilot-service-account, istio-mixer-service-account, istio-ca-service-account and 
istio-ingress-service-account. We need to update or replace these RBAC set up to only allow 
istio-ingress-service-account to access ingress key/cert.       

1. Update RBAC set up for istio-pilot-service-account and istio-mixer-istio-service-account.

   Delete ClusterRoleBinding istio-pilot-admin-role-binding-istio-system and 
   istio-mixer-admin-role-binding-istio-system. 
   Also delete ClusterRole istio-mixer-istio-system.  

   ```bash
   kubectl delete ClusterRoleBinding istio-pilot-admin-role-binding-istio-system
   kubectl delete ClusterRoleBinding istio-mixer-admin-role-binding-istio-system
   kubectl delete ClusterRole istio-mixer-istio-system
   ```
   List all secrets in namespace istio-system that we need to protect using RBAC.
   
   ```bash
   kubectl get secrets -n istio-system
   ```
   This produces the following output:
   
   ```bash
   NAME                                        TYPE                                  DATA      AGE
   default-token-4wwkb                         kubernetes.io/service-account-token   3         7d
   istio-ca-secret                             istio.io/ca-root                      2         7d
   istio-ca-service-account-token-rl4xm        kubernetes.io/service-account-token   3         7d
   istio-egress-service-account-token-vbfwf    kubernetes.io/service-account-token   3         7d
   istio-ingress-certs                         kubernetes.io/tls                     2         7d
   istio-ingress-service-account-token-kwr85   kubernetes.io/service-account-token   3         7d
   istio-mixer-service-account-token-29qbb     kubernetes.io/service-account-token   3         7d
   istio-pilot-service-account-token-t6kmf     kubernetes.io/service-account-token   3         7d
   istio.default                               istio.io/key-and-cert                 3         7d
   istio.istio-ca-service-account              istio.io/key-and-cert                 3         7d
   istio.istio-egress-service-account          istio.io/key-and-cert                 3         7d
   istio.istio-ingress-service-account         istio.io/key-and-cert                 3         7d
   istio.istio-mixer-service-account           istio.io/key-and-cert                 3         7d
   istio.istio-pilot-service-account           istio.io/key-and-cert                 3         7d
   ```
   Create a file istio-pilot-mixer-istio-system.yaml, which defines new ClusterRole that grants  
   access permission to kubernetes.io/service-account-token, istio.io/key-and-cert, and  
   istio.io/ca-root types of resource instances. This file also defines a ClusterRoleBinding to  
   bind this new ClusterRole to service accounts istio-pilot-service-account and 
   istio-mixer-istio-service-account.
   
   ```bash
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: istio-pilot-mixer-istio-system
   rules:
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["default-token-4wwkb"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-service-account-token-rl4xm"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ca-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-egress-service-account-token-vbfwf"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ingress-service-account-token-kwr85"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-mixer-service-account-token-29qbb"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-pilot-service-account-token-t6kmf"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-secret"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.default"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ca-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-egress-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ingress-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-mixer-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-pilot-service-account"]
     verbs: ["get", "list", "watch"]
   ---
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: istio-pilot-mixer-admin-role-binding-istio-system
   subjects:
   - kind: ServiceAccount
     name: istio-pilot-service-account
     namespace: istio-system
   - kind: ServiceAccount
     name: istio-mixer-service-account
     namespace: istio-system
   roleRef:
     kind: ClusterRole
     name: istio-pilot-mixer-istio-system
     apiGroup: rbac.authorization.k8s.io
   ```
   
   ```bash
   kubectl apply -f istio-pilot-mixer-istio-system.yaml
   ```

1. Update RBAC set up for istio-ingress-service-account.

   Delete ClusterRoleBinding istio-ingress-admin-role-binding-istio-system and ClusterRole 
   istio-pilot-istio-system.
   
   ```bash
   kubectl delete clusterrolebinding istio-ingress-admin-role-binding-istio-system
   kubectl delete ClusterRole istio-pilot-istio-system
   ```

   Create istio-ingress-admin-role-binding-istio-system.yaml which defines a new ClusterRole 
   istio-ingress-istio-system, and defines a ClusterRoleBinding 
   istio-ingress-admin-role-binding-istio-system. The ClusterRole istio-ingress-istio-system 
   grants permission to read istio-ingress-certs.
   
   ```bash
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: istio-ingress-istio-system
   rules:
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["default-token-4wwkb"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-service-account-token-rl4xm"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-egress-service-account-token-vbfwf"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ingress-service-account-token-kwr85"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-mixer-service-account-token-29qbb"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-pilot-service-account-token-t6kmf"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-secret"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.default"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ca-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-egress-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ingress-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-mixer-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-pilot-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ingress-certs"]
     verbs: ["get", "list", "watch"]
   ---
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: istio-ingress-admin-role-binding-istio-system
   subjects:
   - kind: ServiceAccount
     name: istio-ingress-service-account
     namespace: istio-system
   roleRef:
     kind: ClusterRole
     name: istio-ingress-istio-system
     apiGroup: rbac.authorization.k8s.io
   ```
   
   ```bash
   kubectl apply -f istio-ingress-admin-role-binding-istio-system.yaml
   ```
   
1. Update RBAC set up for istio-ca-service-account.
Create a file istio-ca-role-binding-istio-system.yaml, which defines ClusterRole 
istio-ca-istio-system. This ClusterRole allows istio-ca-service-account to read and modify 
istio.io/key-and-cert and kubernetes.io/service-account-token types of secrets, and secret instance 
istio-ca-secret.  

   ```bash
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: istio-ca-istio-system
   rules:
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["default-token-4wwkb"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-service-account-token-rl4xm"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-egress-service-account-token-vbfwf"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ingress-service-account-token-kwr85"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-mixer-service-account-token-29qbb"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-pilot-service-account-token-t6kmf"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-secret"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.default"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ca-service-account"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-egress-service-account"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ingress-service-account"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-mixer-service-account"]
     verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-pilot-service-account"]
     verbs: ["get", "list", "watch", "create", "update"]
   ```

   ```bash
   kubectl apply -f istio-ca-role-binding-istio-system.yaml
   ```
1. Verify that the new ClusterRoles work as expected.
   
   ```bash
   kubectl auth can-i get secret/istio-ingress-certs --as system:serviceaccount:istio-system:istio-ingress-service-account -n istio-system
   ```
   whose output should be
   ```bash
   yes
   ```
   In this command, we can replace verb "get" with "list" or "watch", and the output should always 
   be "yes".
   
   ```bash
   kubectl auth can-i get secret/istio-ingress-certs --as system:serviceaccount:istio-system:istio-pilot-service-account -n istio-system
   ```    
   whose output should be
   ```bash
   no - Unknown user "system:serviceaccount:istio-system:istio-pilot-service-account"
   ```
   In this command, we can replace service account with istio-mixer-service-account, or 
   istio-ca-service-account, we can also replace verb "get" with "watch" or "list", and the 
   output should remain the same.
   
   Accessibility to secret resources expect istio-ingress-certs should remain the same for 
   istio-ca-service-account, istio-ingress-service-account, istio-pilot-service-account and
   istio-mixer-service-account.
   ```bash
   kubectl auth can-i get secret/istio-ca-service-account-token-r14xm --as system:serviceaccount:istio-system:istio-ca-service-account -n istio-system
   ```
   whose output should be
   ```bash
   yes
   ```
   
## Configuring ingress for gRPC

The ingress controller currently doesn't support `.` characters in the `path`
field. This is an issue for gRPC services using namespaces. In order to work
around the issue, traffic can be directed through a common dummy service, with
route rules set up to intercept traffic and redirect to the intended services.

1. Create a dummy ingress service:

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: v1
   kind: Service
   metadata:
     name: ingress-dummy-service
   spec:
     ports:
     - name: grpc
       port: 1337
   EOF
   ```

1. Create a catch-all ingress pointing to the dummy service:

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: all-istio-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     rules:
     - http:
         paths:
         - backend:
             serviceName: ingress-dummy-service
             servicePort: grpc
   EOF
   ```

1. Create a RouteRule for each service, redirecting from the dummy service to
   the correct gRPC service:

   ```bash
   cat <<EOF | istioctl create -f -
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: foo-service-route
   spec:
     destination:
       name: ingress-dummy-service
     match:
       request:
         headers:
           uri:
             prefix: "/foo.FooService"
     precedence: 1
     route:
     - weight: 100
       destination:
         name: foo-service
   ---
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: bar-service-route
   spec:
     destination:
       name: ingress-dummy-service
     match:
       request:
         headers:
           uri:
             prefix: "/bar.BarService"
     precedence: 1
     route:
     - weight: 100
       destination:
         name: bar-service
   EOF      
   ```


## Understanding ingresses

Ingresses provide gateways for external traffic to enter the Istio service mesh
and make the traffic management and policy features of Istio available for edge services.

In the preceding steps we created a service inside the Istio service mesh and showed how
to expose both HTTP and HTTPS endpoints of the service to external traffic.
We also showed how to control the ingress traffic using an Istio route rule.

## Cleanup

1. Remove the secret, Ingress Resource definitions and Istio rule.
    
   ```bash
   istioctl delete routerule deny-route status-route
   kubectl delete ingress simple-ingress secure-ingress 
   kubectl delete -n istio-system secret istio-ingress-certs
   ```

1. Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service.

   ```bash
   kubectl delete -f samples/httpbin/httpbin.yaml
   ```


## Further reading

* Learn more about [Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/).

* Learn more about [routing rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html).
