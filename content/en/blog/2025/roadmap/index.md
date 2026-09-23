---
title: "Istio Roadmap for 2025-2026"
description: Looking ahead to what's next for Istio.
publishdate: 2025-07-25
attribution: "Mitch Connors, for the Istio TOC"
keywords: [Istio,roadmap,ambient]
---

Over the next 12 months, we will focus on improving parity between sidecar mode and ambient mode, providing a supported path for sidecar users to migrate to the ambient data plane when they are ready.  We will also revamp our contributor experience, simplifying the process for proposing and implementing new features, and giving recognition to our most valuable contributors. We plan to grow our ecosystem by adding or updating Istio’s integration to various popular cloud native projects and build more case studies for Istio.

## Looking Back

Since 2023, the Istio project has been focused on maturity and innovation, solidifying our position as the best service mesh regardless of sidecars or ambient. These efforts included our CNCF graduation in July 2023, the promotion of Telemetry API and Gateway API to Stable in Istio 1.22, and the promotion of ambient mode to Stable in Istio 1.24. As part of Istio ambient mode reaching GA, we have observed more and more users exploring and adopting it, some of the users are net new Istio users, while others are users of Istio sidecars.  Some of them ran ambient in production and spoke about their experiences at KubeCon EU in April this year. These efforts have made Istio the service mesh of choice for cloud native developers around the world, and we have been excited to accept first code contributions from 154 people in the past 12 months.

## 2025 Themes

### Sidecar to ambient migration

With the promotion of ambient mode to Stable, Istio can now lay claim to being the fastest and most efficient service mesh as well as the most widely used, while being easier to operate than ever. With graduation, we’ve seen a substantial increase in interest, and a corresponding number of requests for a comprehensive migration guide for existing sidecar users.  While our previous efforts to stabilize ambient mode have been targeted at new Istio users, it is clear that the time has come to provide an onramp for our existing user base to migrate to ambient mesh.  While the technical foundations for this migration have been in place for some time (and some brave users have migrated on their own), we will be making new investments in tooling to assess your readiness to migrate, rollback-safe interoperability, and documentation to guide users every step of the way.

In addition to tests, tooling, and documentation, users migrating between data planes should reasonably expect that the Istio features they know and love will continue to work in their new environment.  For this reason, we are investing in closing the most significant functionality gaps between sidecar and ambient mode, specifically by adding support for multi-cluster traffic management and extensibility, which you can read about below.

As we have stated in previous years, we have no intention of ending support for sidecar mode as long as there are users for it.  Migrating to ambient mesh is completely voluntary, and we expect many users will use sidecars for years to come.

### Multi-cluster ambient mesh

Multi-cluster traffic management has long been one of the most valued enterprise features of Istio, and we are hard at work to bring this value to ambient mode users in 2025.  With a multi-cluster mesh, service outages or anomalies in one cluster can dynamically cause requests to fail over to other clusters, potentially in other regions or clouds.  This gives users the ability to run high-availability services in active-active configuration, optimizing compute utilization and traffic costs from a single control plane. Multi-cluster ambient mesh will be available as an Alpha in Istio 1.27, which we plan to release in August.

### The future of extensibility

The Istio project has offered several APIs for extensibility since launch, and none of them has been able to mature to Stable. Of those in use today, Envoy Filters are a powerful tool for tweaking internal proxy configuration, and modifying traffic flow, but are very difficult to use, and pose significant risk during upgrades, which can change the filter integrations in ways that cannot always be predicted.  WebAssembly (Wasm) emerged in 2019 as a powerful tool for Turing-complete modification of traffic, but community support for Wasm compilers and libraries outside the Istio ecosystem has waned substantially since that time, making it difficult for users to safely and securely use Wasm with Istio.

As we plan for 2025 and beyond, it is clear that we need a path to a mature extensibility model for users of sidecars and ambient mode alike.  We plan to address the most common use cases for extensibility, such as local rate limiting, with first class APIs, reducing the frequency with which users require extensibility. However, we recognize that networks are complex, and there will always be cases our APIs don’t cover, when users need a "break glass" option.  The architecture of ambient mode provides some options, such as leveraging the waypoint pattern to accomplish service insertion, adding arbitrary proxies to the network chain, which can then perform arbitrary modifications.  Another similar development is [Envoy’s ext-proc filter](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ext_proc/v3/ext_proc.proto), which sends requests to an arbitrary service for modification before forwarding them to their destination.

With several options on the table for extensibility, who will decide which is best? As always, the final decision lies with you, our users. Please share your thoughts with us about the future of the project in the extensibility channel at [slack.istio.io](https://slack.istio.io/).

## New and Improved Contributor Experience

The Istio community is full of many talented contributors whose daily efforts make this project possible, and the list of contributors is always growing!  However, like all Open Source projects, we are always in need of new contributors, and we recognize that submitting your first PR to Istio is harder than it should be. In 2025, we aim to make authoring your first Istio contribution easier than ever with improved integration with GitHub Codespaces, and regular triage of good first issues! If you’re interested in contributing, we can always use help on Issues labeled User Experience and Documentation. If you’d like to get more involved, consider joining our release manager rotation, which will provide you with two releases as a shadow before taking on primary release management responsibilities. We will also aim to provide better recognition to our contributors through a revamped workgroup leads program, where top contributors can be recognized for their expertise!  With these initiatives, we believe we are setting up the Istio community to grow for years to come.

## Conclusion

This roadmap outlines an exciting near-term for Istio, focusing on a seamless migration path from sidecar to ambient mode, enhanced multi-cluster capabilities, and a refined approach to extensibility. We are also committed to fostering a more welcoming and rewarding environment for our invaluable contributors. These initiatives solidify Istio's position as the leading service mesh, ready to empower cloud native developers with unmatched efficiency, control, and a thriving community.
