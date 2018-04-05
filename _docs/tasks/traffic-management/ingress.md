---
title: Istio Ingress
overview: Describes how to configure Istio Ingress on Kubernetes.

order: 30

layout: docs
type: markdown
redirect_from: /docs/tasks/ingress.html
---
{% include home.html %}

This task describes how to configure Istio to expose a service outside of the service mesh cluster.
In a Kubernetes environment, the [Kubernetes Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)
allows users to specify services that should be exposed outside the
cluster. It allows one to define a backend service per virtual host and path.

Once the Istio Ingress specification is defined, traffic entering the cluster is directed through the `istio-ingress` service. As a result, Istio features, for example, monitoring and route rules, can be applied to the traffic entering the cluster.

The Istio Ingress specification is based on the standard [Kubernetes Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/) specification, with the following differences:

1. Istio Ingress specification contains `kubernetes.io/ingress.class: istio` annotation.

1. All other annotations are ignored.

The following are known limitations of Istio Ingress:

1. Regular expressions in paths are not supported.
1. Fault injection at the Ingress is not supported.

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

1. Create a basic Ingress specification for the httpbin service

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
         - path: /status/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
         - path: /delay/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

   `/.*` is a special Istio notation that is used to indicate a prefix
   match, specifically a
   [rule match configuration]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#matchcondition)
   of the form (`prefix: /`).

### Verifying HTTP ingress

1. Determine the ingress URL:

   * If your cluster is running in an environment that supports external load balancers, use the ingress' external address:

   ```bash
   kubectl get ingress simple-ingress -o wide
   ```

   ```xxx
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

   ```xxx
   169.47.243.100
   ```

   along with the istio-ingress service's nodePort for port 80:

   ```bash
   kubectl -n istio-system get svc istio-ingress
   ```

   ```xxx
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

   ```xxx
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 48
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 404 error

   ```bash
   curl -I http://$INGRESS_HOST/headers
   ```

   ```xxx
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

## Configuring secure ingress (HTTPS)

1. Generate certificate and key for the ingress

   A private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=foo.bar.com"
   ```

1. Create the secret

   Create the secret `istio-ingress-certs` in namespace `istio-system` using `kubectl`. The Istio Ingress will automatically
   load the secret.

   > The secret must be called `istio-ingress-certs` in `istio-system` namespace, for it to be mounted on Istio Ingress.

   ```bash
   kubectl create -n istio-system secret tls istio-ingress-certs --key /tmp/tls.key --cert /tmp/tls.crt
   ```

1. Create the Ingress specification for the httpbin service

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
         - path: /status/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
         - path: /delay/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

   > Because SNI is not yet supported, Envoy currently only allows a single TLS secret in the ingress.
   > That means the secretName field in ingress resource is not used.

### Verifying HTTPS ingress

1. Determine the ingress URL:

   * If your cluster is running in an environment that supports external load balancers,
     use the ingress' external address:

     ```bash
     kubectl get ingress secure-ingress -o wide
     ```

     ```xxx
     NAME             HOSTS     ADDRESS                 PORTS     AGE
     secure-ingress   *         130.211.10.121          80        1d
     ```

     ```bash
     export INGRESS_HOST=130.211.10.121
     ```

   * If load balancers are not supported, use the ingress controller pod's hostIP:

     ```bash
     kubectl -n istio-system get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'
     ```

     ```xxx
     169.47.243.100
     ```

     along with the istio-ingress service's nodePort for port 443:

     ```bash
     kubectl -n istio-system get svc istio-ingress
     ```

     ```xxx
     NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
     istio-ingress   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
     ```

     ```bash
     export INGRESS_HOST=169.47.243.100:32254
     ```

1. Access the httpbin service using _curl_:

   ```bash
   curl -I -k https://$INGRESS_HOST/status/200
   ```

   ```xxx
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 96
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 404 error

   ```bash
   curl -I -k https://$INGRESS_HOST/headers
   ```

   ```xxx
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

1. Configuring RBAC for ingress key/cert

    There are service accounts which can access this ingress key/cert, and this leads to risks of
    leaking key/cert. We can set up Role-Based Access Control ("RBAC") to protect it.
    install/kubernetes/istio.yaml defines `ClusterRoles` and `ClusterRoleBindings` which allow service
    accounts in namespace istio-system to access all secret resources. We need to update or replace
    these RBAC set up to only allow istio-ingress-service-account to access ingress key/cert.

    We can use `kubectl` to list all secrets in namespace istio-system that we need to protect using RBAC.
   ```bash
   kubectl get secrets -n istio-system
   ```
    This produces the following output:
   ```xxx
   NAME                                        TYPE                                  DATA      AGE
   istio-ingress-certs                         kubernetes.io/tls                     2         7d
   istio.istio-ingress-service-account         istio.io/key-and-cert                 3         7d
   ......
   ```

1. Update RBAC set up for istio-pilot-service-account and istio-mixer-istio-service-account

    Record `ClusterRole` istio-mixer-istio-system and istio-pilot-istio-system. We will refer to
    these copies when we redefine them to avoid breaking access permissions to other resources.
   ```bash
   kubectl describe ClusterRole istio-mixer-istio-system
   kubectl describe ClusterRole istio-pilot-istio-system
   ```
    Delete existing `ClusterRoleBindings` and `ClusterRole`.

   ```bash
   kubectl delete ClusterRoleBinding istio-pilot-admin-role-binding-istio-system
   kubectl delete ClusterRoleBinding istio-mixer-admin-role-binding-istio-system
   kubectl delete ClusterRole istio-mixer-istio-system
   ```
    As istio-pilot-istio-system is also bound to istio-ingress-service-account, we will delete
    istio-pilot-istio-system in next step.

    Create istio-mixer-istio-system.yaml, which allows istio-mixer-service-account to read
    istio.io/key-and-cert, and istio.io/ca-root types of secret instances. Refer to the recorded
    copy of istio-mixer-istio-system and add access permissions to other resources.

   ```yaml
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: istio-mixer-istio-system
   rules:
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ca-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-secret"]
     verbs: ["get", "list", "watch"]
   ......
   ---
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: istio-mixer-admin-role-binding-istio-system
   subjects:
   - kind: ServiceAccount
     name: istio-mixer-service-account
     namespace: istio-system
   roleRef:
     kind: ClusterRole
     name: istio-mixer-istio-system
     apiGroup: rbac.authorization.k8s.io
   ```

   ```bash
   kubectl apply -f istio-mixer-istio-system.yaml
   ```

1. Update RBAC set up for istio-pilot-service-account and istio-ingress-service-account

    Delete existing `ClusterRoleBinding` and `ClusterRole`.

   ```bash
   kubectl delete clusterrolebinding istio-ingress-admin-role-binding-istio-system
   kubectl delete ClusterRole istio-pilot-istio-system
   ```

    Create istio-pilot-istio-system.yaml, which allows istio-pilot-service-account to read
    istio.io/key-and-cert, and istio.io/ca-root types of secret instances. Refer to the recorded
    copy of istio-pilot-istio-system and add access permissions to other resources.

   ```yaml
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: istio-pilot-istio-system
   rules:
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ca-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-secret"]
     verbs: ["get", "list", "watch"]
   ......
   ---
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: istio-pilot-admin-role-binding-istio-system
   subjects:
   - kind: ServiceAccount
     name: istio-pilot-service-account
     namespace: istio-system
   roleRef:
     kind: ClusterRole
     name: istio-pilot-istio-system
     apiGroup: rbac.authorization.k8s.io
   ```

   ```bash
   kubectl apply -f istio-pilot-istio-system.yaml
   ```

    Create istio-ingress-istio-system.yaml which allows istio-ingress-service-account to read
    istio-ingress-certs as well as other secret instances. Refer to the recorded copy of
    istio-pilot-istio-system and add access permissions to other resources.

   ```yaml
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: istio-ingress-istio-system
   rules:
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio.istio-ca-service-account"]
     verbs: ["get", "list", "watch"]
   - apiGroups: [""] # "" indicates the core API group
     resources: ["secrets"]
     resourceNames: ["istio-ca-secret"]
     verbs: ["get", "list", "watch"]
   ......
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
   kubectl apply -f istio-ingress-istio-system.yaml
   ```

1. Update RBAC set up for istio-ca-service-account

    Record `ClusterRole` istio-ca-istio-system.
   ```bash
   kubectl describe ClusterRole istio-ca-istio-system
   ```

    Create istio-ca-istio-system.yaml, which updates existing `ClusterRole` istio-ca-istio-system
    that allows istio-ca-service-account to read, create and modify all istio.io/key-and-cert, and
    istio.io/ca-root types of secrets.

   ```yaml
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
    name: istio-ca-istio-system
   rules:
   - apiGroups: [""] # "" indicates the core API group
    resources: ["secrets"]
    resourceNames: ["istio.istio-ca-service-account"]
    verbs: ["get", "list", "watch", "create", "update"]
   - apiGroups: [""] # "" indicates the core API group
    resources: ["secrets"]
    resourceNames: ["istio-ca-secret"]
    verbs: ["get", "list", "watch", "create", "update"]
   ......
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: istio-ca-role-binding-istio-system
   subjects:
   - kind: ServiceAccount
     name: istio-ca-service-account
     namespace: istio-system
   roleRef:
     kind: ClusterRole
     name: istio-ca-istio-system
     apiGroup: rbac.authorization.k8s.io
   ```
   ```bash
   kubectl apply -f istio-ca-istio-system.yaml
   ```
1. Verify that the new `ClusterRoles` work as expected

   ```bash
   kubectl auth can-i get secret/istio-ingress-certs --as system:serviceaccount:istio-system:istio-ingress-service-account -n istio-system
   ```
    whose output should be
   ```xxx
   yes
   ```
    In this command, we can replace verb "get" with "list" or "watch", and the output should always
    be "yes". Now let us test with other service accounts.

   ```bash
   kubectl auth can-i get secret/istio-ingress-certs --as system:serviceaccount:istio-system:istio-pilot-service-account -n istio-system
   ```
    whose output should be
   ```xxx
   no - Unknown user "system:serviceaccount:istio-system:istio-pilot-service-account"
   ```
    In this command, we can replace service account with istio-mixer-service-account, or
    istio-ca-service-account, we can also replace verb "get" with "watch" or "list", and the output
    should look similarly.

    Accessibility to secret resources except istio-ingress-certs should remain the same for
    istio-ca-service-account, istio-ingress-service-account, istio-pilot-service-account and
    istio-mixer-service-account.
   ```bash
   kubectl auth can-i get secret/istio-ca-service-account-token-r14xm --as system:serviceaccount:istio-system:istio-ca-service-account -n istio-system
   ```
    whose output should be
   ```xxx
   yes
   ```

1. Cleanup

    We can delete these newly defined `ClusterRoles` and `ClusterRoleBindings`, and restore original
    `ClusterRoles` and `ClusterRoleBindings` according to those recorded copies.

## Using Istio Routing Rules with Ingress

Istio's routing rules can be used to achieve a greater degree of control
when routing requests to backend services. For example, the following
route rule sets a 4s timeout for all calls to the httpbin service on the
/delay URL.

```bash
cat <<EOF | istioctl create -f -
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: status-route
spec:
  destination:
    name: httpbin
  match:
    # Optionally limit this rule to istio ingress pods only
    source:
      name: istio-ingress
      labels:
        istio: ingress
    request:
      headers:
        uri:
          prefix: /delay/ #must match the path specified in ingress spec
              # if using prefix paths (/delay/.*), omit the .*.
              # if using exact match, use exact: /status
  route:
  - weight: 100
  httpReqTimeout:
    simpleTimeout:
      timeout: 4s
EOF
```

If you were to make a call to the ingress with the URL
`http://$INGRESS_HOST/delay/10`, you will find that the call returns in 4s
instead of the expected 10s delay.

You can use other features of the route rules such as redirects, rewrites,
routing to multiple versions, regular expression based match in HTTP
headers, WebSocket upgrades, timeouts, retries, etc. Please refer to the
[routing rules]({{home}}/docs/reference/config/istio.routing.v1alpha1.html)
for more details.

> Fault injection does not work at the Ingress
>
> When matching requests in the routing rule, use the same exact
> path or prefix as the one used in the Ingress specification.

## Understanding ingresses

Ingresses provide gateways for external traffic to enter the Istio service
mesh and make the traffic management and policy features of Istio available
for edge services.

The `servicePort` field in the Ingress specification can take a port number
(integer) or a name. The port name must follow the Istio port naming
conventions (e.g., `grpc-*`, `http2-*`, `http-*`, etc.) in order to
function properly. The name used must match the port name in the backend
service declaration.

In the preceding steps we created a service inside the Istio service mesh
and showed how to expose both HTTP and HTTPS endpoints of the service to
external traffic. We also showed how to control the ingress traffic using
an Istio route rule.

## Cleanup

1. Remove the secret and Ingress Resource definitions.

   ```bash
   kubectl delete ingress simple-ingress secure-ingress
   kubectl delete -n istio-system secret istio-ingress-certs
   ```

1. Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service.

   ```bash
   kubectl delete -f samples/httpbin/httpbin.yaml
   ```

## What's next

* Learn more about [Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/).

* Learn more about [Routing Rules]({{home}}/docs/reference/config/istio.routing.v1alpha1.html).
