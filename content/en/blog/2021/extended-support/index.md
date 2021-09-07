---
title: "Announcing Extended Support for Istio 1.9"
description: "Allowing for Less Frequent Upgrades."
publishdate: 2021-09-03
attribution: "Mitch Connors (Google), Lin Sun (Solo.io)"
keywords: [upgrade,Istio,support]
---

In keeping with our 2021 theme of improving Day 2 Istio operations, the Istio team has been evaluating extending the support window for our releases to give users more time to upgrade.  For starters, we are extending the support window of Istio 1.9 by six weeks, to October 5, 2021.  We hope that this additional support window will allow the many users who are currently using Istio 1.9 to upgrade, either to Istio 1.10 or directly to Istio 1.11. By overlapping support between 1.9 and 1.11, we intend to create a stable cadence of upgrade windows twice a year for users upgrading directly across two minor versions (i.e. 1.9 to 1.11).  Users who prefer upgrading through each minor release to get all the latest and greatest features may continue doing so quarterly.

{{< image width="100%" link="./extended_support.png" caption="Extended Support and Upgrades" >}}

During this extended period of support, Istio 1.9 will receive CVE and critical bug fixes only, as our goal is simply to provide users with time to migrate off the release and on to 1.10 or 1.11.   And speaking of users, we would love to hear how we’re doing at improving your Day 2 experience of Istio.  Is two upgrades per year not the right number?  Is a six week upgrade window too short?  Please share your thoughts with us on [slack](https://slack.istio.io) (in the user-experience channel), or on [twitter](https://twitter.com/istiomesh).  Thanks!
