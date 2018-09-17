---
title: Build & Release Cadence
description: How we manage, number, and support Istio releases.
weight: 6
icon: cadence
---

We produce new builds of Istio on a daily basis. Around once a month or so, we take one of these daily
builds and run it through a number of additional qualification tests and tag the build as a Snapshot release.
Around once a quarter or so, we take one of these Snapshot releases, run through a bunch more tests
and tag the build as a Long Term Support (LTS) release. Finally, if we find something wrong with an
LTS release, we issue patches.

The different types (Daily, Snapshot, LTS) represent different product quality levels and different levels of support
from the Istio team. In this context, *support* means that we will produce patch releases for critical issues and
offer technical assistance. Separately, 3rd parties and partners may offer longer-term support solutions.

|Type             | Support Level                                            | Quality and Recommended Use
|-----------------|----------------------------------------------------------|----------------------------
|Daily Build      | No support                                               | Dangerous, may not be fully reliable. Useful to experiment with.
|Snapshot Release | Support is provided for the latest snapshot release only | Expected to be quite stable, but use in production should be limited to an as-needed basis. Usually only adopted by bleeding edge users, or users seeking specific features.
|LTS Release      | Support is provided until 3 months after the next LTS    | Safe to deploy in production. Users are encouraged to upgrade to these releases as soon as possible.
|Patches          | Same as the corresponding Snapshot/LTS release           | Users are encouraged to adopt patch releases as soon as they are available for a given release.

You can find available releases on the [releases page](https://github.com/istio/istio/releases),
and if you're the adventurous type, you can learn about our daily builds on the [daily builds wiki](https://github.com/istio/istio/wiki/Daily-builds).
You can find high-level releases notes for each LTS release [here](/about/notes).

## Naming Scheme

Prior to Istio 0.8, we increased the product's version number on a monthly basis. Effective with 0.8,
we will increase the product's version number only for LTS releases.

Our naming scheme for LTS releases is:

{{< text plain >}}
<major>.<minor>.<LTS patch level>
{{< /text >}}

where `<minor>` is increased for every LTS release, and `<LTS patch level>` counts the number of patches for the
current LTS release. A patch is usually a small change relative to the LTS.

For snapshot releases, our naming scheme is:

{{< text plain >}}
<major>.<minor>.0-snapshot.<snapshot count>
{{< /text >}}

where `<major>.<minor>.0` represent the next LTS, and
`<snapshot count>` starts at 0 and increases for every snapshot leading up to the
next LTS.

In the unlikely event we need to issue a patch to a snapshot, it is numbered as:

{{< text plain >}}
<major>.<minor>.0-snapshot.<snapshot count>.<snapshot patch level>
{{< /text >}}
