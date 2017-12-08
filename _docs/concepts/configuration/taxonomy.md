---
title: Taxonomy
overview: Classification of Istio confguration through functional view.

order: 15

layout: docs
type: markdown
---
{% include home.html %}

Istio configuration is component oriented. Each component exposes independently evolved
configuration resources to the Istio end user, such as Mixer configuration,
 Pilot configuration, etc. Another way to understand the configuration is through their functionality and the entities where they apply on. 
The following diagram illustrates such concept. 

<figure><img src="./img/space.svg" alt="Config taxonomy." title="Istio Config Taxonomy"/>
<figcaption>Istio Config Taxonomy</figcaption></figure>

## Adapter config

Configs used by Mixer adapters to forward service management runtime request to
infrastructure backends. Adapter config may contain infrastructure backend config
runtime paramters, access credentials, and policy definitions. See
[details]({{home}}/docs/reference/config/mixer/adapters).

## API management config

Configs for service API management, including [IDL config](#idl-config) and
[policy config](#policy-config).

## Authentication config

Defines how to mutually identify and establish a secure connection to a
service. The identification includes service identity and end-user
(per-request) identity. Secure communication includes traffic within the mesh
and across mesh boundaries, such as mTLS configs. Per request authentication
config live in Proxy such as JWT token validation.

## Authorization config

Istio service resource access policy definition, such as Istio RBAC, defining
who can access which.

## Backend config

Backend config is not part of [Istio config](#istio-config). These are the
configs for Istio infrastructure backends. Backend config defines the
management resources, such as quota, monitoring that will be used to accept
runtime control requests from Istio through Mixer adapters. Backend config may
live in cloud vendors.

## Catalog config

Config for service to expose a standard Open Service Broker Interface (OSBI)
and provide Istio automatic multi-tenancy (AMT) feature. 

## Component config

Refer to service [management config](#management-config) for each Istio core
service component: Proxy, Mixer, Broker, Auth.

## Core config

Istio core component configs. Typically the configs to install Pilot, Proxy,
Mixer, Broker. Currently it only includes [deployment
config](#deployment-config). Once Istio components are managed as mesh services
("Istio on Istio"), it will include [management config](#management-config).

## Deployment config

The config to deploy Istio component or services. These are environment
specific. On Kubernetes, they are deployment, namespace, service, RBAC,
configMap resources. 

## IDL config

Service interface definition, such as API IDL, protocol.

## Istio config

The entire Istio config space where an Istio operator can work on. It includes
[core config](#core-config) and [service config](#service-config).

## Logging config

Define log entries, format, and input data.

## Management config

The config that defines and manages the traffic sent to a service. This
includes [traffic config](#traffic-config), [catalog config](#catalog-config),
[IDL config](#idl-config), [authentication config](#authentication-config),
[adapter config](#adapter-config), and [policy config](#policy-config).

## Mesh config

Mesh config refers to a particular scoped [service config](#service-config)
that applies to all services in a mesh.

## Metric config

Define metric types, metric instances, and metric rules. 

## Namespace config

Namespace config refers to a particular scoped [service
config](#service-config) that applies to all services in a namespace.

## Policy config

Define service management policies, including [quota config](#quota-config),
[metric config](#metric-config), [logging config](#logging-config), and
[authorization config](#authorization-config).

## Quota config

Define quota types and quota policies.

## Runtime config

Istio mesh runtime configs, mostly for configuring Envoy runtime. They are
currently configured through configMap resources. See
[details]({{home}}/docs/reference/config/service-mesh.html). 

## Security config

Define Istio service security aspects including [authentication
config](#authentication-config) and [authorization config](#authorization-config).

## Service config

The configs that apply to a mesh service, to install or control the data flow
that passes in/out of the service. Service config includes service [deployment
config](#deployment-config) and service [management
config](#management-config). The configs can be scoped to apply to more than
one service.

## Traffic config

Also refered as networking config. Defines the mesh service network. This
includes routing rules, destination policy, ingress rules, and egress rules.
See [details]({{home}}/docs/reference/config/traffic-rules).
