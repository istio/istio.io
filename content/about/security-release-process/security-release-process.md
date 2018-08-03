---
title: Security Release Process
description: Release process for Istio security vulnerabilities.
weight: 35
page_icon: /img/security-release.svg
---

Istio follows the following process when releasing patches for critical
security vulnerabilities.

## Security vulnerability disclosures

Please refer to the [disclosure process](/about/security-vulnerabilities/).

## Istio security team

Security vulnerabilities should be handled quickly and privately.
The primary goal of this process is to reduce the total time users are
vulnerable to publicly known exploits.

The Istio security team is responsible for organizing the entire response
including internal communication and external disclosure. The team will need help
from relevant developers and release leads to successfully run this process.

The Istio security team consists of volunteers subscribed to the
private [`istio-security-vulnerabilities@google.com`](mailto:istio-security-vulnerabilities@google.com)
list.

### Istio security team membership

Membership to the Istio security team is based on roles defined below.

#### Roles

##### Fix lead

Per issue, Fix Lead sees the issue through to the end.

##### Release lead

Per issue, Release Lead is in charge of releasing the fix.

##### Disclosure lead

Handles public messaging around the bug, and the documentation of how to upgrade.
Explains the severity of the vulnerability and requests CVEs (Common Vulnerability Exposures).

##### Triage

Makes sure the relevant people are notified, also responds to issues
that are not actually security vulnerability issues.
This person is the escalation path for a vulnerability if it is one.

##### Infra

Makes sure the fixes are tested appropriately. This person is the build cop.
It is the person you call when you need help testing, or the release branch is all
messed up.

#### Scheduled rotation

Each week has a primary & secondary for each role. If something comes up that week,
primary owns it. Secondary is there if we can't get a hold of the primary.

## Patch, release, and public communication

For each vulnerability, Fix Lead drives the schedule using his/her best
judgment based on severity, development time, and the feedback from Release Lead.
If the fix relies on another upstream project's disclosure timeline, that will
adjust the process as well. Fix Lead will work with the upstream project
owners to determine the fix timeline and best protect the users.

### Fix team organization

The fix team for a vulnerability should be formed within the first 24 hours of
the disclosure.

- Fix Lead will work quickly to identify relevant engineers from the affected
projects and packages and CC those engineers into the disclosure thread. This selected
developers become members of the fix team. A rough guess is to invite all owners in
the OWNERS file from the affected packages.
- Fix Lead will help the fix team to get access of private security repositories
for developing the fix.

### Fix development process

The following steps should be completed within the 1-7 days of the disclosure.

- Fix Lead and the fix team will create a [CVSS](https://www.first.org/cvss/specification-document)
using the [CVSS Calculator](https://www.first.org/cvss/calculator/3.0).
They will also use the [Severity Thresholds - How We Do Vulnerability Scoring](#severity-thresholds-how-we-do-vulnerability-scoring)
to determine the effect and severity of the vulnerability. Fix Lead makes the final call on the
calculated risk; it is better to move quickly than make the perfect assessment.
- The fix team will notify Fix Lead once the fix is ready to be released.

If the CVSS score is under 4.0 ([a low severity score](https://www.first.org/cvss/specification-document#i5))
or the assessed risk is low, the fix team can decide to slow the release process down in the face of
holidays, developer bandwidth, and etc. These decisions must be discussed on
the private [`istio-security-vulnerabilities@google.com`](mailto:istio-security-vulnerabilities@google.com)
list.

### Fix disclosure process

With the fix development underway, Disclosure Lead needs to come up with a
communication plan for the community. This disclosure process should begin after the
fix team has developed a fix or mitigation so that a realistic timeline can be
communicated to users.

#### Disclosure of a forthcoming fix to users

- Disclosure Lead will email [istio-announce@googlegroups.com](https://groups.google.com/forum/#!forum/istio-announce)
informing users that a security vulnerability has been disclosed and that a fix will be made
available at `YYYY-MM-DD HH:MM UTC` in the future. This time is the release date
of the fix and it will be a new release on
[`github.com/istio/istio/releases`](https://github.com/istio/istio/releases).
- The fix team will provide any mitigating steps users can take until a fix is available.

The communication to users should be actionable. They should know when to
apply patches, understand exact mitigation steps, and etc.

#### Fix release

- Release Lead will ensure all the binaries are built, publicly available, and functional
before the release date. TODO: this will require a private security build process.
- Release Lead will create a new patch release branch from the latest patch release
tag + the fix from the security branch. As an example, if `v1.0.0` is the latest patch release,
a new branch will be created called `v1.0.1` which includes only the patches required to fix the
vulnerability.
- Release Lead will cherry-pick the patches onto the master branch and all relevant
release branches. The fix team will review the fix.
- Release Lead will merge these PRs as quickly as possible. Changes shouldn't be made to the
commits even for a typo in the CHANGELOG as this will change the git SHA of the already built
and commits, leading to confusion and potentially conflicts as the fix is cherry-picked around branches.
- Disclosure Lead will request a CVE from [DWF](https://github.com/distributedweaknessfiling/DWF-Documentation)
and include the CVSS and release details.
- Disclosure Lead will email [istio-announce@googlegroups.com](https://groups.google.com/forum/#!forum/istio-announce)
that the fix has been released, including the CVE number, and the location of the patched binaries,
to get wide distribution and user action. As much as possible this email should be actionable and include
instructions on applying the fix to user environments.
- Fix Lead will remove the fix team from the private security repo.

### Retrospective

These steps should be completed 1-5 days after releasing a fix for critical
security vulnerabilities.
The retrospective process [should be blameless](https://landing.google.com/sre/book/chapters/postmortem-culture.html).

- Fix Lead will send a retrospective of the process to istio-dev@googlegroups.com, including details
on everyone involved, the timeline of the process, links to relevant PRs that introduced the issue,
if relevant, and any critiques of the response and release process.
- Release Lead and the fix team are also encouraged to send their own feedback on the process to
istio-dev@googlegroups.com. Honest critique is the only way we are going to get good at this as
a community.
