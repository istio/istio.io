---
title: Enabling Policy Enforcement
description: This task shows you how to enable Istio policy enforcement.
weight: 1
keywords: [policies]
---

This task shows you how to enable Istio policy enforcement.

## At install time

In the default Istio installation profile, policy enforcement is disabled. To install Istio
with policy enforcement on, use the `--set values.global.disablePolicyChecks=false` and `--set values.pilot.policy.enabled=true` install option.

Alternatively, you may [install Istio using the demo profile](/docs/setup/getting-started/),
which enables policy checks by default.

## For an existing Istio mesh

1. Check the status of policy enforcement for your mesh.

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: true
    {{< /text >}}

    If policy enforcement is enabled (`disablePolicyChecks` is false), no further action is needed.

1. Update the `istio` configuration to enable policy checks.

    Execute the following command from the root Istio directory:

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.disablePolicyChecks=false --set values.pilot.policy.enabled=true
    configuration "istio" replaced
    {{< /text >}}

1. Validate that policy enforcement is now enabled.

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: false
    {{< /text >}}
