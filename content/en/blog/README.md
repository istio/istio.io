# Istio blog

The [Istio blog](https://istio.io/blog) is owned by the [Steering Committee](https://github.com/istio/community/tree/master/steering) and run by the [Editorial Team](#leadership).

This section covers documentation, processes, and roles for the blog.

## Editorial Team 

- **Editorial Lead:** [steering member company A], [steering member company B]
- **Technical Editors:** [contributor], [contributor]
- **Copy Editors:** [technical writer], [technical writer], [María Cruz](https://github.com/macruzbar)
- **Blog Community Managers:**  [María Cruz](https://github.com/macruzbar), [independent contributor]

## Contact

- Slack: [#toc-steering-questions](https://istio.slack.com/archives/C018VK0T9JT)

## Submit a Post

Anyone can write a blog post and submit it for review. Content highlighting commercial products is allowed, provided it calls out how the product integrates with Istio in a clear way. Blog posts promoting commercial products will be labeled as such on the Istio blog. Please refer to the [blog guidelines](#blog-guidelines) for more guidance.

To submit a blog post, follow the steps below.

1. [Sign the Contributor License Agreement](https://github.com/istio/community/blob/master/CONTRIBUTING.md#contributor-license-agreements) if you have not yet done so.
1. Familiarize yourself with the Markdown format for existing blog posts in the [docs repository](https://github.com/istio/istio.io/tree/master/content/en/blog). 
1. Write your blog post in a text editor of your choice.
1. Choose at least one of the following tags for your blogpost: New releases, Announcements, Trainings, Events, Commercial products
1. (Optional) If you need help with markdown, check out [StakEdit](https://stackedit.io/app#) or read [GitHub's formatting syntax](https://help.github.com/en/github/writing-on-github/basic-writing-and-formatting-syntax) for more information. 
1. Create a new folder in the directory for the corresponding year in the [blog repository](https://github.com/istio/istio.io/tree/master/content/en/blog), and click **Create new file**.
1. Paste your post into the editor and save it. Name the file in the following way: *folder-for-your-blog/index.md* , but don’t put the date in the file name. The editorial team will work with you on the final file name, and the date on which the post will be published.
1. When you save the file, GitHub will walk you through the pull request (PR) process.
1. A reviewer is assigned to all pull requests automatically. The reviewer checks your submission, and works with you on feedback and final details. When the pull request is approved, the post will be scheduled for publication.
1. Ping editorial team members on Slack [#docs](https://istio.slack.com/archives/C50V5EATT) channel with a link to your recently created PR. 

### Blog Guidelines
The Istio blog only publishes original content; we do not re-post content that has been posted elsewhere.

#### Suitable content:
- Istio new feature releases and project updates
- Tutorials and demos 
- Use cases
- Content that relates vendor or platform to Istio installation and use 

#### Unsuitable Content:
- Content that is disparaging to Istio project, its functionalities or community
- Content that does not observe our [code of conduct](https://github.com/istio/community/blob/master/CONTRIBUTING.md#code-of-conduct)
- Blogs that do not address Istio in any way
- Content that doesn't interact with Istio APIs or interfaces
- Blatant vendor pitches

#### Vendor blog posts
Contributors are encouraged to show how Istio’s functionality can be extended and interesting use cases can be addressed using technology, and it is fine to write about commercial technology in doing so. Each vendor has a limit of once a month to post on the Istio blog. However, it is important that the blog post teaches the reader something they didn’t know about Istio rather than coming across as a commercial for the vendor’s technology. It will be up to the judgement of the editorial lead whether a post is “just an ad” or is truly adding value.

## Review Process

After a blog post is submitted as a PR, it is automatically assigned to a reviewer.

Each blog post requires a `lgtm` label from at least one Editorial Lead and one Technical Editor (if the Editorial Lead requires this second technical review). If the blog is not technical, the other approval has to come from a Copy Editor. Once the necessary labels are in place, one of the reviewers will add an `approved` label, and the blog will be published when the PR is merged.

### Timelines

Blog posts can take up to **1 week** to review. If you'd like to request an expedited review, please say so on your message when you ping the Editorial Team on Slack.
