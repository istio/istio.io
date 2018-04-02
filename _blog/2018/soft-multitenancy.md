---
title: "Istio Multitenancy Support"
overview: Using Kubernetes namespace and RBAC to create an Istio soft multitenancy environment
publish_date: March 21, 2018
subtitle: Using multiple Istio control planes and RBAC to create multitenancy
attribution: John Joyce and Rich Curran

order: 92

layout: blog
type: markdown
redirect_from: "/blog/soft-multitenancy.html"
---
{% include home.html %}
Multitenancy is commonly used in many environments across many different applications,
but the implementation details and functionality provided on a per tenant basis does not
follow one model in all environments.  The [Kubernetes multitenancy working group](
https://github.com/kubernetes/community/blob/master/wg-multitenancy/README.md)
is working to define the multitenant use cases and functionality that should be available
within Kubernetes. From their work so far it is clear that only "soft multitenancy" is
possible due to the inability to fully protect against malicious containers or workloads
gaining access to the other pods or kernel resources.

## Defining soft multitenancy for Istio
While discussing the strengths and benefits of deploying applications on top of Istio, it
became apparent that there are multitenant use cases for Istio even within this Kubernetes
"soft multitenancy" definition that does not provide absolute protection amongst tenants.
A viable use case for this scenario is shared corporate infrastructure where malicious
actions are not expected but a clean separation of the tenants is still required. A few
different multitenant models can be considered.
1.	A single mesh with multiple applications, one for each tenant on the mesh. The cluster
administrator gets control and visibility mesh wide and across all applications, while the
tenant administrator only gets control of a specific application.
1.	A single Istio control plane with multiple meshes, one mesh per tenant. The cluster
administrator gets control and visibility across the entire Istio control plane and all
meshes, while the tenant administrator only gets control of a specific mesh.
1.	A single Kubernetes control plane with multiple Istio control planes, one per tenant.
The cluster administrator gets control and visibility across all the Istio control planes,
while the tenant administrator only gets control of a specific Istio instance.
1.	A single cloud environment (cluster controlled), but multiple Kubernetes control planes
(tenant controlled).

Options 1, 2 and 4 either can't be properly supported without code changes or don't fully
address the use cases. Current Istio capabilities are well suited to providing option 3 so 
this blog will focus on that option.  Best practices for deploying multiple
tenant applications per cluster require the use of a namespace. Namespace-based scoping is already
supported in Istio modules. Therefore code changes are not required to support option 3.  
This blog will provide a high level description of the requirements to 
deploy multiple Istio control planes (one per tenant) on a single Kubernetes cluster.

## Deployment details
### Multiple Istio control planes
Deploying multiple Istio control planes starts by replacing all `namespace` references
in a manifest file with the desired namespace. Using istio.yaml as an example, if two tenant
level Istio control planes are required; the first can use the istio.yaml default name of
*istio-system* and a second control plane can be created by generating a new yaml file with
a different namespace.
```bash
cat istio.yaml | sed s/istio-system/istio-system1/g > istio-system1.yaml
```
Note that the execution of these two yaml files is the responsibility of the cluster
administrator, not the tenant level adminstrator. Additional RBAC restrictions will also
need to be configured and applied by the cluster administrator, limiting the tenant
administrator to only the assigned namespace.

If the Istio [addons]({{home}}/docs/tasks/telemetry/) are required then the manifests must
be updated to match the configured `namespace` in use by the tenant's Istio control plane.

### Split common and namespace specific resources
The manifest files in the Istio repositories create both common resources that would
be used by all Istio control planes as well as resources that are replicated per control
plane. Although it is a simple matter to deploy multiple control planes by replacing the
*istio-system* namespace references as described above, a better approach is to split the
manifests into a common part that is deployed once for all tenants and a tenant
specific portion. All the CustomResourceDefinitions (CRDs), the roles and the role
bindings should be separated out from the provided Istio manifests.  Additionally, the
roles and role bindings in the provided Istio manifests are probably unsuitable for a
multitenant environment and should be modified or augmented as described in the next
section.

### Kubernetes RBAC for Istio control plane resources
To restrict a tenant administrator to a single Istio namespace, the cluster
administrator would create a manifest containing, at a minimum, a `Role` and `RoleBinding`
similar to the one below. In this example, a tenant administrator named *sales-admin*
is limited to the namespace *istio-system1*. A completed manifest would contain many
more `apiGroups` under the `Role` providing resource access to the tenant administrator.
```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: istio-system1 
  name: ns-access-for-sales-admin-istio-system1
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["*"]
  verbs: ["*"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: access-all-istio-system1
  namespace: istio-system1
subjects:
- kind: User
  name: sales-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ns-access-for-sales-admin-istio-system1
  apiGroup: rbac.authorization.k8s.io

```

### Watching specific namespaces for service discovery
In addition to creating RBAC rules limiting the tenant administrator access to a specific Istio
control plane, the Istio manifest must be updated to specify the application namespace that
Pilot should watch for creation of its xDS cache. This is done by starting the Pilot component
with the additional command line arguments `--appNamespace, ns-1`.  Where *ns-1* is the
namespace that the tenant’s application will be deployed in. An example snippet from the
istio-system1.yaml file is included below.
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: istio-pilot
  namespace: istio-system1
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  replicas: 1
  template:
    metadata:
      labels:
        istio: pilot
    spec:
      serviceAccountName: istio-pilot-service-account
      containers:
      - name: discovery
        image: docker.io/<user ID>/pilot:<tag>
        imagePullPolicy: IfNotPresent
        args: ["discovery", "-v", "2", "--admission-service", "istio-pilot", "--appNamespace", "ns-1"]
        ports:
        - containerPort: 8080
        - containerPort: 443

```

### Deploying the tenant application in a namespace
Now that the cluster administrator has created the tenant's namespace (ex. *istio-system1*) and
Pilot's service discovery has been configured to watch for a specific application
namespace (ex. *ns-1*), create the application manifests to deploy in that tenant's specific
namespace. For example:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ns-1
```
And add the namespace reference to each resource type included in the applications manifest
file.  For example:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
  namespace: ns-1
```
Although not shown, the application namespaces will also have RBAC settings limiting access
to certain resources. These RBAC settings could be set by the cluster administrator and/or
the tenant administrator.

### Using Istioctl commands in a multitenant environment
When defining [route rules]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#RouteRule)
or [destination policies]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#DestinationPolicy),
it is necessary to ensure that the `istioctl` command is scoped to
the namespace the Istio control plane is running in to ensure the resource is created
in the proper namespace. Additionally, the rule itself must be scoped to the tenant's namespace
so that it will be applied properly to that tenant's mesh.  The *-i* option is used to create
(or get or describe) the rule in the namespace that the Istio control plane is deployed in.
The *-n* option will scope the rule to the tenant's mesh and should be set to the namespace that
the tenant's app is deployed in. Note that the *-n* option can be skipped on the command line if
the .yaml file for the resource scopes it properly instead.

For example, the following command would be required to add a route rule to the *istio-system1*
namespace:
```bash
istioctl –i istio-system1 create -n ns-1 -f route_rule_v2.yaml
```
And can be displayed using the command:
```bash
istioctl -i istio-system1 -n ns-1 get routerule
```
```bash
NAME			KIND					NAMESPACE
details-Default		RouteRule.v1alpha2.config.istio.io	ns-1
productpage-default	RouteRule.v1alpha2.config.istio.io	ns-1
ratings-default		RouteRule.v1alpha2.config.istio.io	ns-1
reviews-default		RouteRule.v1alpha2.config.istio.io	ns-1
```

### Test results
Following the instructions above, a cluster administrator can create an environment limiting,
via RBAC and namespaces, what a tenant administrator can deploy. 

After deployment, accessing the Istio control plane pods assigned to a specific tenant
administrator is permitted:
```bash
kubectl get pods -n istio-system
```
```bash
NAME                                      READY     STATUS    RESTARTS   AGE
grafana-78d649479f-8pqk9                  1/1       Running   0          1d
istio-ca-ffbb75c6f-98w6x                  1/1       Running   0          1d
istio-ingress-68d65fc5c6-dnvfl            1/1       Running   0          1d
istio-mixer-5b9f8dffb5-8875r              3/3       Running   0          1d
istio-pilot-678fc976c8-b8tv6              2/2       Running   0          1d
istio-sidecar-injector-7587bd559d-5tgk6   1/1       Running   0          1d
prometheus-cf8456855-hdcq7                1/1       Running   0          1d
servicegraph-75ff8f7c95-wcjs7             1/1       Running   0          1d
```
However, accessing all the cluster's pods is not permitted:
```bash
kubectl get pods --all-namespaces
```
```bash
Error from server (Forbidden): pods is forbidden: User "dev-admin" cannot list pods at the cluster scope
```
And neither is accessing another tenant's namespace:
```bash
kubectl get pods -n istio-system1
```
```bash
Error from server (Forbidden): pods is forbidden: User "dev-admin" cannot list pods in the namespace "istio-system1"
```

The tenant administrator can deploy applications in the application namespace configured for
that tenant. As an example, updating the [Bookinfo]({{home}}/docs/guides/bookinfo.html)
manifests and then deploying under the tenant's application namespace of *ns-0*, listing the
pods in use by this tenant's namespace is permitted:
```bash
kubectl get pods -n ns-0
```
```bash
NAME                              READY     STATUS    RESTARTS   AGE
details-v1-64b86cd49-b7rkr        2/2       Running   0          1d
productpage-v1-84f77f8747-rf2mt   2/2       Running   0          1d
ratings-v1-5f46655b57-5b4c5       2/2       Running   0          1d
reviews-v1-ff6bdb95b-pm5lb        2/2       Running   0          1d
reviews-v2-5799558d68-b989t       2/2       Running   0          1d
reviews-v3-58ff7d665b-lw5j9       2/2       Running   0          1d
```
But accessing another tenant's application namespace is not:
```bash
kubectl get pods -n ns-1
```
```bash
Error from server (Forbidden): pods is forbidden: User "dev-admin" cannot list pods in the namespace "ns-1"
```

If the [addon tools]({{home}}/docs/tasks/telemetry/), example
[prometheus]({{home}}/docs/tasks/telemetry//querying-metrics.html), are deployed
(also limited by an Istio `namespace`) the statistical results returned would represent only
that traffic seen from that tenant's application namespace.

## Conclusion
The evaluation performed indicates Istio has sufficient capabilities and security to meet a
small number of multitenant use cases. It also shows that Istio and Kubernetes __cannot__
provide sufficient capabilities and security for many other use cases, especially those use
cases that require complete security and isolation between untrusted tenants. The improvements
required to reach a more secure model of security and isolation require work in container
technology, ex. Kubernetes, rather than improvements in Istio capabilities.

## Future work
Allowing a single Istio control plane to control multiple meshes would be an obvious next
feature. An additional improvement is to provide a single mesh that can host different
tenants with some level of isolation and security between the tenants.  This could be done
by partitioning within a single control plane using the same logical notion of namespace as 
Kubernetes. A [document](https://docs.google.com/document/d/14Hb07gSrfVt5KX9qNi7FzzGwB_6WBpAnDpPG6QEEd9Q)
has been started within the Istio community to define additional use cases and the
Istio functionality required to support those use cases.

## Issues, limitiations or caveats
### Known issues 
* The CA (Certificate Authority) and mixer Istio pod logs from one tenant's Istio control
plane (ex. *istio-system* `namespace`) contained 'info' messages from a second tenant's
Istio control plane (ex *istio-system1* `namespace`).
### Challenges with the different models
At the beginning of this blog a few different models of multitenancy were described.  This section will
briefly discuss some of challenges with those models with the current state of Istio or Kubernetes 
code. 

Current Istio capabilities are poorly suited to support the first model as it lacks
sufficient RBAC capabilities to support cluster versus tenant operations. Additionally,
having multiple tenants under one mesh is too insecure with the current mesh model and the 
way Istio drives configuration to the envoy proxies. 

Regarding the 2nd option the current Istio paradigm assumes a single mesh per Istio control
plane. The needed changes to support this model are substantial. They would require 
finer grained scoping of resources and security domains based on namespaces, as well as,
additional Istio RBAC changes. This model will likely be addressed by future work, but not
currently possible. 

The fourth model doesn’t satisfy most use cases, as most cluster administrators prefer
a common Kubernetes control plane which they provide as a PaaS to their tenants.
Additionally, case 4 is easily provided in many environments already so is not interesting to 
further describe here.

## References

* Video on Kubernetes multitenancy support, [Multi-Tenancy Support & Security Modeling with RBAC and Namespaces](https://www.youtube.com/watch?v=ahwCkJGItkU), and the [supporting slide deck ](https://schd.ws/hosted_files/kccncna17/21/Multi-tenancy%20Support%20%26%20Security%20Modeling%20with%20RBAC%20and%20Namespaces.pdf).
* Kubecon talk on security that discusses Kubernetes support for "Cooperative soft multitenancy", [Building for Trust: How to Secure Your Kubernetes ](https://www.youtube.com/watch?v=YRR-kZub0cA).
* Kubernetes documentation on [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) and [namespaces](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/).
* Kubecon slide deck on [Multitenancy Deep Dive](https://schd.ws/hosted_files/kccncna17/a9/kubecon-multitenancy.pdf).
* Google document on [Multi-tenancy models for Kubernetes](https://docs.google.com/document/d/15w1_fesSUZHv-vwjiYa9vN_uyc--PySRoLKTuDhimjc/edit#heading=h.3dawx97e3hz6). (Requires permission)
* Cloud Foundry WIP document, [Multi-cloud and Multi-tenancy](https://docs.google.com/document/d/14Hb07gSrfVt5KX9qNi7FzzGwB_6WBpAnDpPG6QEEd9Q)
* [Istio Auto Multi-Tenancy 101](https://docs.google.com/document/d/12F183NIRAwj2hprx-a-51ByLeNqbJxK16X06vwH5OWE/edit#heading=h.x0f9qplja3q)
