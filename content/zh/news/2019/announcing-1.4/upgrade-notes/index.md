---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.4.
weight: 20
---

This page describes changes you need to be aware of when upgrading from
Istio 1.3 to 1.4.  Here, we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.3.

## Traffic management

Services of type `http` are no longer allowed on port 443. This change was made to prevent protocol conflicts with external HTTPS services.

If you depend on this behavior, there are a few options:

* Move the application to another port.
* Change the protocol from type `http` to type `tcp`
* Specify the environment variable `PILOT_BLOCK_HTTP_ON_443=false` to the Pilot deployment. Note: this may be removed in future releases.

See [Protocol Selection](/docs/ops/traffic-management/protocol-selection/) for more information about specifying the protocol of a port

## Configuration management

We introduced OpenAPI v3 schemas in the Kubernetes [Custom Resource Definitions (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) of Istio resources. The schemas describe the Istio resources and help ensure the Istio resources you create and modify are structurally correct.

If one or more fields in your configurations are unknown or have wrong types, they will be rejected by the Kubernetes API server when you create or modify Istio resources. This feature, `CustomResourceValidation`, is on by default for Kubernetes 1.9+ clusters. Please note that existing configurations already in Kubernetes are __NOT__ affected if they stay unchanged.

To help with your upgrade, here are some steps you could take:

* After upgrading Istio, run your Istio configurations with `kubectl apply --dry-run` so that you are able to know if the configurations can be accepted by the API server as well as any possible unknown and/or invalid fields to the API server. (`DryRun` feature is on by default for Kubernetes 1.13+ clusters.)
* Use the [reference documentation](/docs/reference/config/) to confirm and correct the field names and data types.
* In addition to structural validation, you can also use `istioctl x analyze` to help you detect other potential issues with your Istio configurations. Refer to [here](/docs/ops/diagnostic-tools/istioctl-analyze/) for more details.

If you choose to ignore the validation errors, add `--validate=false` to your `kubectl` command when you create or modify Istio resources. We strongly discourage doing so however, since it is willingly introducing incorrect configuration.
