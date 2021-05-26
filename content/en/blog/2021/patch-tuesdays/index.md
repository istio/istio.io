---
title: "Updates to how Istio security releases are handled: Patch Tuesday, embargoes, and 0-days"
description: The Product Security working group announces Patch Tuesdays, how 0-days and embargoes are handled, updates to the security best practices page and the notification of the early disclosure list.
publishdate: 2021-05-11
attribution: "Jacob Delgado (Aspen Mesh)"
keywords: [cve,product security]
---

While most of the work in the Istio Product Security Working Group is done behind the scenes, we are listening
to the community in setting expectations for security releases. We understand that it is difficult for mesh
administrators, operators and vendors to be aware of security bulletins and security releases.

We currently disclose vulnerabilities and security releases via numerous channels:

* [istio.io](https://istio.io) via our [Release Announcements](/news/releases/) and [Security Bulletins](/news/security/)
* [Discuss](https://discuss.istio.io/c/announcements/5)
* announcements channel on [Slack](https://istio.slack.com)
* [Twitter](https://twitter.com/IstioMesh)
* [RSS](/news/feed.xml)

When operating any software, it is preferable to plan for possible downtime when upgrading. Given the work that the Istio
community is doing around Day 2 operations in 2021, the Environments working group has done a good job to streamline many
upgrade issues users have seen. The Product Security Working Group intends to help Day 2 operations by having routine
security release days so that upgrade operations can be planned in advance for our users.

## Patch Tuesdays

The Product Security working group is intending to ship a security release the 2nd Tuesday of each month. These security
releases may contain fixes for multiple CVEs. It is the intent of the Product Security working group to have these
security releases not contain any other fixes, although that may not always be possible.

When the Product Security working group intends to ship an upcoming security patch, an
announcement will be made on [the Istio discussion
board](https://discuss.istio.io/c/announcements/5) 2 weeks prior to release. If you're
running Istio in production,  we suggest you watch the Announcements category to be
notified of such a release. If no such announcement is made there will not be a security
release for that month, barring some exceptions listed below.

### First Patch Tuesday

We are pleased to announce that [Istio 1.9.5](/news/releases/1.9.x/announcing-1.9.5/), and the final release of Istio 1.8,
[1.8.6](/news/releases/1.8.x/announcing-1.8.6/), are the first security releases to fit this pattern. As Istio 1.10 will
be shipping soon we are intending to continue this new tradition in June.

These releases fix 3 CVEs. Please see the release pages for information regarding the specific CVEs fixed.

## Unscheduled security releases

### 0-day vulnerabilities

Unfortunately, 0-day vulnerabilities cannot be planned. Upon disclosure, the Product Security Working Group will
need to issue an out-of-band security release. The above methods will be used to disclose such issues, so please use
at least one of them to be notified of such disclosures.

### Third party embargoes

Similar to 0-day vulnerabilities, security releases can be dictated by third party embargoes, namely Envoy.
When this occurs, Istio will release a same-day patch once the embargo is lifted.

## Security Best Practices

The [Istio Security Best Practices](/docs/ops/best-practices/security/) has seen many improvements over the past few
months. We recommend you check it regularly, as many of our recent security bulletins can be mitigated by utilizing
methods discussed in the Security Best Practices page.

## Early Disclosure List

If you meet [the criteria](https://github.com/istio/community/blob/master/EARLY-DISCLOSURE.md#membership-criteria) to be
a part of the [Istio Early Disclosure](https://github.com/istio/community/blob/master/EARLY-DISCLOSURE.md) list, please
apply for membership. Patches for upcoming security releases will be made available to the early disclosure list ~2 weeks
prior to Istio's Patch Tuesday.

There will be times when an upcoming Istio security release will also need patches from Envoy. We cannot redistribute
Envoy patches due to their embargo. [Please refer to Envoy's guidance](https://github.com/envoyproxy/envoy/security/policy)
on how to join their early disclosure list.

## Security Feedback

The Product Security Working Group holds bi-weekly meetings on Tuesdays from 9:00-9:30 Pacific. For more information see
the [Istio Working Group Calendar](https://calendar.google.com/calendar/embed?src=4uhe8fi8sf1e3tvmvh6vrq2dog%40group.calendar.google.com&ctz=America%2FLos_Angeles).

Our next public meeting will be held on May 25, 2021. Please join us!
