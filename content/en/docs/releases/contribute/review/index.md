---
title: Documentation Review Process
description: Shows you how changes to the Istio documentation and website are reviewed and approved.
weight: 7
aliases:
  - /about/contribute/review
  - /latest/about/contribute/review
keywords: [contribute,community,github,pr,documentation,review, approval]
owner: istio/wg-docs-maintainers
test: n/a
---

The maintainers and working group leads of the Istio Docs Working Group (WG) approve
all changes to the [Istio website](/docs/).

A **documentation reviewer** is a trusted contributor that approves content that
meets the acceptance criteria described in the [review criteria](#review-criteria).
All content reviews follow the process described in [Reviewing content PRs](#review-content-prs).

Only Docs Maintainers and WG Leads can merge content into the [istio.io repository](https://github.com/istio/istio.io).

Content for Istio often needs to be reviewed on short notice and not all content
has the same relevance. The last minute nature of contributions and the finite
number of reviewers make the prioritization of content reviews necessary to
function at scale. This page provides clear review criteria to ensure all review
work happens **consistently**, **reliably** and follows the **same quality standards**.

## Review content PRs

Documentation reviewers, maintainers, and WG leads follow a clear process to
review content PRs to ensure all reviews are consistent. The process is as
follows:

1. The **Contributor** submits a new content PR to the istio.io repository.
1. The **Reviewer** performs a review of the content and determines if it meets the
   acceptance criteria.
1. The **Reviewer** adds any technical WG pertinent for the content if the
   contributor hasn't already.
1. The **Contributor** and the **Reviewer** work together until the content
   meets all required acceptance criteria and the issues are addressed.
1. If the content is urgent and meeting the supplemental acceptance criteria
   requires significant effort, the **Reviewer** files a follow up issue on
   the istio.io repository to address the problems at a later date.
1. The **Contributor** addresses all required and supplemental feedback as
   agreed by the Reviewer and Contributor. Any feedback filed in the follow up
   issues is addressed later.
1. When a **technical** WG lead or maintainer approves the content PR, the
   **Reviewer** can approve the PR.
1. If a Docs WG maintainer or lead reviewed the content, they not only approve,
   but they also merge the content. Otherwise, maintainers and leads are automatically
   notified of the **Reviewer's** approval and prioritize approving and merging
   the already reviewed content.

The following diagram depicts the process:

{{< image width="75%" ratio="45.34%"
    link="./review-process.svg"
    alt="Documentation review process"
    title="Documentation review process"
    >}}

- **Contributors** perform the steps in the gray shapes.
- **Reviewers** perform the steps in the blue shapes.
- **Docs Maintainers and WG Leads** perform the steps in the green shapes.

## Follow up issues

When a **Reviewer** files a follow up issue as part of the
[review process](#review-content-prs), the GitHub issue must include the
following information:

- Details about the [supplemental acceptance criteria](#supplemental-acceptance-criteria)
  the content failed to meet.
- Link to the original PR.
- Username of the technical Subject Matter Experts (SMEs).
- Labels to sort the issues.
- Estimate of work: Reviewers provide their best estimate of how long it would
  take to address the remaining issues working alongside the original
  contributor.

## Review criteria

Our review process supports our [code of conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct)
by making our review criteria transparent and applying it to all content contributions.

Criteria has two tiers: required and supplemental.

### Required acceptance criteria

- Technical accuracy: At least one technical WG lead or maintainer reviews and
  approves the content.
- Correct markup: All linting and tests pass.
- Language: Content must be clear and understandable. To learn more see the
  [highlights](https://developers.google.com/style/highlights) and
  [general principles](https://developers.google.com/style/tone) of the Google developer
  style guide.
- Links and navigation: The content has no broken links and the site builds properly.

### Supplemental acceptance criteria

- Content structure: Information structure enhances the readers' experience.
- Consistency: Content adheres to all recommendations in the
  [Istio contribution guides](/docs/releases/contribute/)
- Style: Content adheres to the [Google developer style guide](https://developers.google.com/style).
- Graphic assets: Diagrams follow the Istio [diagram creation guide](/docs/releases/contribute/diagrams/).\
- Code samples: Content provides relevant, testable, and working code samples.
- Content reuse: Any repeatable content follows a reusability strategy using
  boilerplate text.
- Glossary: New terms are added to the glossary with clear definitions.
