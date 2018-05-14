---
title: Build & Release Cadence
description: How we manage, number, and support Istio releases.
weight: 5
---

We produce new builds of Istio on a daily basis. Around once a month or so, we take one of these daily
builds and run it through a number of additional qualification tests and tag the build as an Alpha release.
Around once a quarter or so, we take one of these Alpha releases, run through a bunch more tests
and tag the build as a Long Term Support (LTS) release. Finally, if we find something wrong with an Alpha
or LTS release, we issue patches.

The different types (Daily, Alpha, LTS) represent different product quality levels and different levels of support
from the Istio team. In this context, *support* means that we will produce patch releases for critical issues and
offer technical assistance. Separately, 3rd parties and partners may offer longer-term support solutions.

|Type          | Support Level                                         | Quality and Recommended Use
|--------------+-------------------------------------------------------+----------------------------
|Daily Build   | No support                                            | Dangerous, may not be fully reliable. Useful to experiment with.
|Alpha Release | Support is provided for the latest Alpha release only | Expected to be quite stable, but use in production should be limited to an as-needed basis. Usually only adopted by bleeding edge users, or users seeking specific features.
|LTS Release   | Support is provided until 3 months after the next LTS | Safe to deploy in production. Users are encouraged to upgrade to these releases as soon as possible.
|Patches       | Same as corresponding Alpha/LTS release               | Users are encouraged to adopt patch releases as soon as they are available for a given release

You can find available releases on the [releases page](https://github.com/istio/istio/releases),
and if you're the adventurous type, you can get learn about our daily build on the [daily builds wiki](https://github.com/istio/istio/wiki/Daily-builds).

## Numbering Scheme

Prior to Istio 0.8, we increased the product's version number on a monthly basis. Effective with 0.8,
we will increase the product's version number only for LTS releases.

Our naming scheme for LTS releases is:

```plain
<major>.<minor>.<patch level>
```

where `minor` is increased for every LTS release, and `patch level` counts the number of patches for the
current LTS release.

For Alpha releases, our numbering scheme is:

```plain
<major>.<minor>.<patch level>-alpha.<alpha count>
```

where `major` and `minor` represent the number of the next LTS release, `patch level` counts the number of
patches for the Alpha release, and `alpha count` starts at 0 and increases for every Alpha release leading up
to the next LTS.
