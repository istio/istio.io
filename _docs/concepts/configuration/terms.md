---
title: Adapter config
type: markdown
---
Configs used by Mixer adapters to forward service management runtime request to
infrastructure backends. Adapter config may contain infrastructure backend config
runtime paramters, access credentials, and policy definitions. See
[details]({{home}}/docs/reference/config/mixer/adapters).
---
title: API management config
type: markdown
---
Configs for service API management, including [IDL config](#idl-config) and
[policy config](#policy-config).
---
title: Authentication(AuthN) config
type: markdown
---
Defines how to mutually identify and establish a secure connection to a
service. The identification includes service identity and end-user
(per-request) identity. Secure communication includes traffic within the mesh
and across mesh boundaries, such as mTLS configs. Per request authentication
config live in Proxy such as JWT token validation.
---
title: Authorization(AuthZ) config
type: markdown
---
Istio service resource access policy definition, such as Istio RBAC, defining
who can access which.
---
title: Backend config
type: markdown
---
Backend config is not part of [Istio config](#istio-config). These are the
configs for Istio infrastructure backends. Backend config defines the
management resources, such as quota, monitoring that will be used to accept
runtime control requests from Istio through Mixer adapters. Backend config may
live in cloud vendors.
---
title: Catalog config
type: markdown
---
Config for service to expose a standard Open Service Broker Interface (OSBI)
and provide Istio automatic multi-tenancy (AMT) feature. 
---
title: Component config
type: markdown
---
Refer to service [management config](#management-config) for each Istio core
service component: Proxy, Mixer, Broker, Auth.
---
title: Core config
type: markdown
---
Istio core component configs. Typically the configs to install Pilot, Proxy,
Mixer, Broker. Currently it only includes [deployment
config](#deployment-config). Once Istio components are managed as mesh services
("Istio on Istio"), it will include [management config](#management-config).
---
title: Deployment config
type: markdown
---
The config to deploy Istio component or services. These are environment
specific. On Kubernetes, they are deployment, namespace, service, RBAC,
configMap resources. 
---
title: IDL config
type: markdown
---
Service interface definition, such as API IDL, protocol.
---
title: Istio config
type: markdown
---
The entire Istio config space where an Istio operator can work on. It includes
[core config](#core-config) and [service config](#service-config).
---
title: Logging config
type: markdown
---
Define log entries, format, and input data.
---
title: Management config
type: markdown
---
The config that defines and manages the traffic sent to a service. This
includes [traffic config](#traffic-config), [catalog config](#catalog-config),
[IDL config](#idl-config), [authentication config](#authentication-config),
[adapter config](#adapter-config), and [policy config](#policy-config).
---
title: Mesh config
type: markdown
---
Mesh config refers to a particular scoped [service config](#service-config)
that applies to all services in a mesh.
---
title: Metric config
type: markdown
---
Define metric types, metric instances, and metric rules. 
---
title: Namespace config
type: markdown
---
Namespace config refers to a particular scoped [service
config](#service-config) that applies to all services in a namespace.
---
title: Policy config
type: markdown
---
Define service management policies, including [quota config](#quota-config),
[metric config](#metric-config), [logging config](#logging-config), and
[authorization config](#authorization-config).
---
title: Quota config
type: markdown
---
Define quota types and quota policies.
---
title: Runtime config
type: markdown
---
Istio mesh runtime configs, mostly for configuring Envoy runtime. They are
currently configured through configMap resources. See
[details]({{home}}/docs/reference/config/service-mesh.html). 
---
title: Security config
type: markdown
---
Define Istio service security aspects including [authentication
config](#authentication-config) and [authorization config](#authorization-config).
---
title: Service config
type: markdown
---
The configs that apply to a mesh service, to install or control the data flow
that passes in/out of the service. Service config includes service [deployment
config](#deployment-config) and service [management
config](#management-config). The configs can be scoped to apply to more than
one service.
---
title: Traffic config
type: markdown
---
Also refered as networking config. Defines the mesh service network. This
includes routing rules, destination policy, ingress rules, and egress rules.
See [details]({{home}}/docs/reference/config/traffic-rules).
