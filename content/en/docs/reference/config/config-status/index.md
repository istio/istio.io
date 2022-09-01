---
title: Configuration Status Field
description: Describes the role of the `status` field in configuration workflow.
weight: 21
owner: istio/wg-user-experience-maintainers
test: no
---

{{< warning >}}
This feature is in the Alpha stage, see
[Istio Feature Status](/docs/releases/feature-stages/). Your feedback is welcome in the
[Istio User Experience discussion](https://discuss.istio.io/c/UX/23). Currently,
this feature is tested only for single, low volume clusters with a single
control plane revision.
{{< /warning >}}

Istio 1.6 and later provides information about the propagation of configuration
changes through the mesh, using the `status` field of the resource.
Status is disabled by default, and can be enabled during install with
(you must also enable `config_distribution_tracking`):

{{< text bash >}}
$ istioctl install --set values.pilot.env.PILOT_ENABLE_STATUS=true --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set values.global.istiod.enableAnalysis=true
{{< /text >}}

The `status` field contains the state of a resource's configuration with various
informational messages, including:

* The resource's readiness.
* How many data plane instances are associated with it.
* Information for the output of tools, such as `istioctl analyze`.

For example, the `kubectl wait` command monitors the `status` field to determine
whether to unblock configuration and resume. For more information, see
[Wait for Resource Status to Apply Configuration](/docs/ops/configuration/mesh/config-resource-ready/).

## View the `status` field

You can view the contents of the `status` field of a resource using
`kubectl get`. For example, to view the status of a virtual service, use the following
command:

{{< text bash >}}
$ kubectl get virtualservice <service-name> -o yaml
{{< /text >}}

In the output, the `status` field contains several nested fields with details
about the process of propagating configuration changes through the mesh.

{{< text yaml >}}
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2019-12-26T22:06:34Z"
    message: "61/122 complete"
    reason: "stillPropagating"
    status: "False"
    type: Reconciled
  - lastProbeTime: null
    lastTransitionTime: "2019-12-26T22:06:56Z"
    message: "1 Error and 1 Warning found. See validationMessages field for details"
    reason: "errorsFound"
    status: "False"
    type: PassedAnalysis
  validationMessages:
  - code: IST0101
    level: Error
    message: 'Referenced gateway not found: "bogus-gateway"'
  - code: IST0102
    level: Warn
    message: 'mTLS not enabled for virtual service'
{{< /text >}}

## The `conditions` field

Conditions represent possible states of the resource. The `type` field of a
condition can have the following values:

* `PassedAnalysis`
* `Reconciled`

When you apply a configuration, a condition of each of these types is added to the
`conditions` field.

The `status` field of the `Reconciled` type condition is initialized to `False`
to indicate the resource is still in the process of being distributed to all the proxies.
When finished reconciling, the status will become `True`. The `status` field might
transition to `True` instantaneously, depending on the speed of the cluster.

The `status` field of the `PassedAnalysis` type condition will have a value of
`True` or `False` depending on whether or not Istio's background analyzers have
detected a problem with your config. If `False`, the problem(s) will be detailed in the
`validationMessages` field.

The `PassedAnalysis` condition is an informational field only. It does not
block the application of an invalid configuration. It is possible for the status to
indicate that validation failed, but applying the configuration was successful.
This means Istio was able to set the new configuration, but the configuration was
invalid, likely due to a syntax error or similar problem.

## The `validationMessages` field

In case of a validation failure, check the `validationMessages` field for
more information. The `validationMessages` field has details about the validation
process, such as error messages indicating that Istio cannot apply the
configuration, and warning or informational messages that did not result in an
error.

If the condition of type `PassedValidation` has a status of `False`, there will
be `validationMessages` explaining the problem. There might be messages present
when `PassedValidation` status is `True`, because those are informational
messages.

For validation message examples, see
[Configuration Analysis Messages](/docs/reference/config/analysis/).
