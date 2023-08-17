---
title: "Istio Ambient Service Mesh Merged to Istio’s Main Branch"
description: A significant milestone for ambient mesh.
publishdate: 2023-02-28
attribution: "John Howard (Google), Lin Sun (Solo.io)"
keywords: [istio,ambient]
---

Istio ambient service mesh was [launched in Sept 2022](/blog/2022/introducing-ambient-mesh/) in an experimental branch, introducing a new data plane mode for Istio without sidecars. Through collaboration with the Istio community, across Google, Solo.io, Microsoft, Intel, Aviatrix, Huawei, IBM and others, we are excited to announce that Istio ambient mesh has graduated from the experimental branch and merged to Istio’s main branch! This is a significant milestone for ambient mesh, paving the way for releasing ambient in Istio 1.18 and installing it by default in Istio’s future releases.

## Major Changes from the Initial Launch

Ambient mesh is designed for simplified operations, broader application compatibility, and reduced infrastructure cost. The ultimate goal of ambient is to be transparent to your applications and we have made a few changes to make the ztunnel and waypoint components simpler and lightweight.

* The ztunnel component has been rewritten from the ground up to be fast, secure, and lightweight. Refer to [Introducing Rust-Based Ztunnel for Istio Ambient Service Mesh](/blog/2023/rust-based-ztunnel/) for more information.
* We made significant changes to simplify waypoint proxy’s configuration to improve its debuggability and performance. Refer to [Istio Ambient Waypoint Proxy Made Simple](/blog/2023/waypoint-proxy-made-simple/) for more information.
* Added the `istioctl x waypoint` command to help you conveniently deploy waypoint proxies, along with `istioctl pc workload` to help you view workload information.
* We gave users the ability to explicitly bind Istio policies such as AuthorizationPolicy to waypoint proxies vs selecting the destination workload.

## Get involved

Follow our [getting started guide](http://istio.io/latest/docs/ops/ambient/getting-started/) to try the ambient pre-alpha build today. We'd love to hear from you! To learn more about ambient:

* Join us in the #ambient and #ambient-dev channel in Istio’s [slack](https://slack.istio.io).
* Attend the weekly ambient contributor [meeting](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings) on Wednesdays.
* Check out the [Istio](http://github.com/istio/istio) and [ztunnel](http://github.com/istio/ztunnel) repositories, submit issues or PRs!
