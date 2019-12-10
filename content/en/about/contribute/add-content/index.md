---
title: Adding New Documentation
description: Details how to contribute new documentation to Istio.
weight: 3
aliases:
    - /docs/welcome/contribute/writing-a-new-topic.html
    - /docs/reference/contribute/writing-a-new-topic.html
    - /about/contribute/writing-a-new-topic.html
    - /create
keywords: [contribute]
---

To contribute new documentation to Istio, just follow these steps:

1. Choose the [type of content](#content-types) you wish to contribute.
1. [Choose a title](#choosing-a-title).
1. Write your contribution following our [documentation contribution guides](/about/contribute).
1. Submit your contribution to our [GitHub repository](https://github.com/istio/istio.io).
1. Follow our [review process](/about/contribute/review) until your contribution
   is merged.

## Content types

Different audiences need different types of information. To provide readers with
the information they need to be successful, you need to choose the right type of
content to address their needs. To make it easy for you to choose, the following
table shows the supported content types, their intended audiences, and the goals
each type tries to achieve:

<table>
    <thead>
        <tr>
            <th>Content type</th>
            <th>Goals</th>
            <th>Audiences</th>
        </tr>
    </thead>
    <tr>
      <td>Concepts</td>
      <td>Explain some significant aspect of Istio. For example, a concept page
      describes the configuration model of a feature and explains its functionality.
      Concept pages don't include sequences of steps. Instead, provide links to
      corresponding tasks.</td>
      <td>Readers that want to understand how features work with only basic
      knowledge of the project.</td>
    </tr>
    <tr>
      <td>Reference pages</td>
      <td>Provide exhaustive and detailed technical information. Common examples
      include API parameters, command-line options, configuration settings, and
      advanced procedures. Reference content is generated from the Istio code
      base and tested for accuracy.
      </td>
      <td>Readers with advanced and deep technical knowledge of the project that
      need specific bits of information to complete advanced tasks.</td>
    </tr>
    <tr>
      <td>Examples</td>
      <td>Describe a working and stand-alone example that highlights a set of
      features, an integration of Istio with other projects, or an end-to-end
      solution for a use case. Examples must use an existing Istio setup as a
      starting point. Examples must include an automated test since they are maintained for technical accuracy.
      </td>
      <td>Readers that want to quickly run the example themselves and
      experiment. Ideally, readers should be able to easily change the example
      to produce their own solutions.</td>
    </tr>
    <tr>
      <td>Tasks</td>
      <td>Shows how to achieve a single goal using Istio features. Tasks contain procedures written
      as a sequence of steps. Tasks provide minimal
      explanation of the features, but include links to the concepts that
      provide the related background and knowledge. Tasks must include automated
      tests since they are tested and maintained for technical accuracy.</td>
      <td>Readers that want to use Istio features.</td>
    </tr>
    <tr>
      <td>Setup pages</td>
      <td>Focus on the installation steps needed to complete an Istio
      deployment. Setup pages must include automated tests since they tested and maintained for technical accuracy.
      </td>
      <td>New and existing Istio users that want to complete a deployment.</td>
    </tr>
    <tr>
      <td>Blog posts</td>
      <td>
        Focus on Istio or products and technologies related to it. Blog posts fall in one of the following three categories:
        <ul>
        <li>Posts detailing the author’s experience using and configuring Istio, especially those that articulate a novel experience or perspective.</li>
        <li>Posts highlighting Istio features.</li>
        <li>Posts detailing how to accomplish a task or fulfill a specific use case using Istio. Unlike Tasks and Examples, the technical accuracy of blog posts is not maintained and tested after publication.</li>
        </ul>
      </td>
      <td>Readers with basic understanding of the project that want to learn
      about it in an anecdotal, experiential, and more informal way.</td>
    </tr>
    <tr>
      <td>News entries</td>
      <td>
        Focus on timely information about Istio and related events. News entries typically announce new releases or upcoming events.
      </td>
      <td>Readers that want to quickly learn what's new and what's happening in
      the Istio community.</td>
    </tr>
    <tr>
      <td>FAQ entries</td>
      <td>
        Provide quick answers to common questions. Answers don't introduce any
        concepts. Instead, they provide practical advice or insights. Answers
        must link to tasks, concepts, or examples in the documentation for readers to learn more.
      </td>
      <td>Readers with specific questions that are looking for brief answers and
      resources to learn more.</td>
    </tr>
    <tr>
      <td>Operation guides</td>
      <td>
        Focus on practical solutions that address specific problems encountered while running Istio in a real-world setting.
      </td>
      <td>Service mesh operators that want to fix problems or implement
      solutions for running Istio deployments.</td>
    </tr>
  </table>

## Choosing a title

Choose a title for your topic that has the keywords you want search engines to
find. All content files in Istio are named `index.md`, but each content file is
within a folder that uses the keywords in the topic's title,
separated by hyphens, all in lower case. Keep folder names as short as possible
to make cross-references easier to create and maintain.

## Submit your contribution to GitHub

If you are not familiar with GitHub, see our [working with GitHub guide](/about/contribute/github)
to learn how to submit documentation changes.

If you want to learn more about how and when your contributions are published,
see the [section on branching](/about/contribute/github#branching-strategy) to understand
how we use branches and cherry picking to publish our content.
