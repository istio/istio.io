---
title: "Happy 7th Birthday, Istio!"
description: Celebrating Istio’s momentum and exciting future.
publishdate: 2024-05-24
attribution: "Lin Sun (Solo.io), for the Istio Steering Committee"
keywords: [istio,birthday,momentum,future]
---

{{< image width="80%"
    link="./7th-birthday.png"
    alt="Happy 7th birthday, Istio!"
    >}}

On this day in 2017, [Google and IBM announced the launch of the Istio service mesh](https://techcrunch.com/2017/05/24/google-ibm-and-lyft-launch-istio-an-open-source-platform-for-managing-and-securing-microservices/). Istio
is an open technology that enables developers to seamlessly connect, manage, and secure networks of different
services — regardless of platform, source, or vendor. We can hardly believe that Istio turns seven today! To
celebrate the project’s 7th birthday, we wanted to highlight Istio’s momentum and its exciting future.

## Rapid adoption among users

Istio, the most widely adopted service mesh project in the world, has been gathering significant momentum since
its inception in 2017. Last year Istio joined Kubernetes, Prometheus, and other stalwarts of the cloud native
ecosystem with [its CNCF graduation](https://www.cncf.io/announcements/2023/07/12/cloud-native-computing-foundation-reaffirms-istio-maturity-with-project-graduation/).
End users range from digital native startups to the world’s largest financial institutions and telcos, with [case studies](/about/case-studies/)
from companies including eBay, T-Mobile, Airbnb, Splunk, FICO, T-Mobile, Salesforce, and many others.

Istio’s control plane and sidecar are the #3 and #4 most downloaded images on Docker Hub, each with over [10 billion downloads](https://hub.docker.com/search?q=istio).

{{< image width="80%"
    link="./dockerhub.png"
    alt="Docker Hub downloads of Istio!"
    >}}

We have over 35,000 GitHub stars on [Istio’s main repository](https://github.com/istio/istio/), with continuing growth. Thank you everyone who starred the istio/istio repo.

{{< image width="80%"
    link="./github-stars.png"
    alt="GitHub stars of the istio/istio repo!"
    >}}

We asked a few of our users for their thoughts on the occasion of Istio’s 7th birthday:

{{< quote >}}
**Today, Istio serves as the backbone of Airbnb's service mesh, managing all our traffic between hundreds of thousands of workloads. Five years since adopting Istio, we've always been happy
with that decision. It's truly amazing to be part of this vibrant and supportive community. Happy Birthday, Istio!**

— Weibo He, Senior Staff Software Engineer at Airbnb
{{< /quote >}}

{{< quote >}}
**Istio has powered our ability to rapidly deploy and test microservices in a production-like, isolated environment
along with the dependent services. This approach, known as Isolates, enables eBay's developers to identify defects earlier in the development
lifecycle, increase the stability of live environments by reducing flakiness, and build confidence in automated
production deployments. Ultimately, this has accelerated the development process and improved the success rate of production deployments.**

— Sudheendra Murthy, Principal Engineer & Service Mesh Architect at eBay
{{< /quote >}}

{{< quote >}}
**Istio enhances the security of our cloud platform while simplifying observability by integrating distributed
tracing and OpenTelemetry. This combination provides
robust security features and deep insights into system performance, enabling more effective monitoring and
troubleshooting of our distributed services.**

— Sathish Krishnan, Distinguished Engineer at UBS
{{< /quote >}}

{{< quote >}}
**Adopting Istio has been a game changer for our engineering organization in our journey of adopting a
microservices based architecture. Its batteries-included approach has allowed us to easily manage traffic routing, gain deep visibility into our service to
service interactions with distributed tracing, and extensibility via WASM plugins. Its comprehensive feature set
has made it an essential part of our infrastructure, and has allowed our engineers to decouple application code
from infrastructure plumbing.**

— Shray Kumar, Principal Software Engineer at Bluecore
{{< /quote >}}

{{< quote >}}
**Istio is amazing, I've been using it for 4 to 5 years and found it very comfortable to manage thousands of
gateways for tens of thousands of pods with very low latency. If you need to set up a very secure infrastructure, Istio is a great friend. Also, it's
excellent for infrastructures that demand a lot of security and need to be aligned with PCI/HIPAA/SoC2 standards.**

— Ezequiel Arielli, Head of Cloud Platform at SIGMA Financial AI
{{< /quote >}}

{{< quote >}}
**Istio helps us secure our environments in a standardized way across all our deployments for our various
customers. The flexibility and customization of Istio really
helps us build better applications by delegating encryption, authorization, and authentication to the service mesh
and not having to implement that across our application code base.**

— Joel Millage, Software Engineer at BCubed
{{< /quote >}}

{{< quote >}}
**We use Istio at Predibase extensively to simplify communication between our multi-cluster mesh that helps deploy
and train open source fine-tuned LLM models with low latency and failover. With Istio, we get a lot of out of the box functionality that would
otherwise take us weeks to implement.**

— Gyanesh Mishra, Cloud Infrastructure Engineer at Predibase
{{< /quote >}}

{{< quote >}}
**Istio is without a doubt the most complete and feature full Service Mesh platform on the market. This success is the direct result of an engaged community that helps itself and is always
included in the project directions. Congratulations on the anniversary, Istio!**

— Daniel Requena, SRE at iFood
{{< /quote >}}

{{< quote >}}
**We've been using Istio in production for years now, it’s a key component of our infrastructure allowing us to
securely connect micro-services, and provide ingress/egress traffic management and first-class observability.
The community is great and each release brings a lot of exciting features.**

— Frédéric Gaudet, Senior SRE at BlablaCar
{{< /quote >}}

## Amazing diversity of contributors and vendors

Over the past year, our community has observed tremendous growth in terms of both the number of contributing
companies and the number of contributors. Recall that Istio had 500 contributors when it turned three years
old? We have had over 1,700 contributors in the past year!

With Microsoft's Open Service Mesh team joining
the Istio community, we added Azure to the [list of clouds and enterprise Kubernetes vendors](/about/ecosystem/) providing Istio-compatible solutions, including Google Cloud, Red Hat OpenShift, VMware Tanzu, Huawei Cloud, DaoCloud, Oracle Cloud, Tencent Cloud, Akamai Cloud and Alibaba Cloud. We are also delighted to see the Amazon Web Services team publish the [EKS Blueprint for Istio](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/)
due to high demand from users wanting to run Istio on AWS.

Specialist network software providers are also driving Istio forward, with Solo.io, Tetrate and F5 Networks all offering enterprise Istio solutions that will run in any environment.

Below are the top contributing companies for the past year, with Solo.io, Google, and DaoCloud taking the top
three places. While most of these companies are Istio vendors, Salesforce and Ericsson are end users, running Istio in production!

{{< image width="80%"
    link="./contribution.png"
    alt="Top Istio contributing companies for the past year!"
    >}}

Here are some thoughts from our community leaders:

{{< quote >}}
**Service mesh adoption has been steadily rising over the past few years as cloud native adoption has matured
across industries. Istio has helped drive part of this maturation since they
graduated last year in CNCF and we wish them a fantastic birthday. We look forward to watching and supporting this
continued growth as the Istio team adds new features like ambient mode and simplifies the service mesh experience.**

— Chris Aniszczyk, CTO of CNCF
{{< /quote >}}

{{< quote >}}
**Service Meshes are core to microservice architectures, a hallmark of cloud native. Istio's birthday celebrates the proliferation and
importance not only of observability and traffic management, but the increasing demand for secure-by-default
communications through encryption, mutual authentication, and many other core security tenets that simplify the
adoption, integration, and deployment experience.**

— Emily Fox, CNCF TOC chair and Senior Principal Software Engineer at Red Hat
{{< /quote >}}

{{< quote >}}
**In my opinion Istio isn’t a service mesh. It’s a collaborative community of users and contributors who happen to
deliver the world’s most popular service mesh. Happy birthday to this amazing community! It’s been a fantastic seven years, and
I’m looking forward to celebrating many more with my friends and colleagues from around the world in the Istio community!**

— Mitch Connors, Istio Technical Oversight Committee member and Principal Engineer at Microsoft
{{< /quote >}}

{{< quote >}}
**It has been a privilege and a fulfilling experience to be part of the world's most popular service mesh team for
the past two years. Happy to
see Istio grow from a CNCF incubating to graduated project, and even happier to see the momentum and passion with
which the latest and greatest 1.22 release was done. Wishing many more successful releases in the coming years.**

— Faseela K, Istio Steering Committee member and Cloud Native Developer at Ericsson
{{< /quote >}}

{{< quote >}}
**What makes Istio unique is the community full of developers, users, and vendors from all across the globe working
together to make Istio the best and most powerful open service mesh in the industry. It’s the strength of the community that
has made Istio so successful and now under CNCF I look forward to seeing Istio as the de facto service mesh
standard for all cloud native applications.**

— Neeraj Poddar, Istio Technical Oversight Committee member and VP of Engineering at Solo.io
{{< /quote >}}

{{< quote >}}
**It has been a privilege to have worked with the Istio community over the last 5 years. There has been an
abundance of contributors whose dedication, passion, and hard work have made my time on the project truly
enjoyable. The community has many users who provide feedback to help make Istio the best service mesh. I continue to be
amazed by what the community does, and look forward to seeing what successes we will have in the future.**

— Eric Van Norman, Istio Technical Oversight Committee member and Advisory Software Engineer at IBM
{{< /quote >}}

{{< quote >}}
**Istio is the backbone of the Salesforce service mesh infrastructure which today powers a few trillion requests per day across all our services. We solve a lot of complicated problems with mesh. It’s great to be part of this journey and contribute to the community. Istio has matured into a reliable service mesh over the years and at the same time continues to innovate. We are excited about what's to come in future!**

— Rama Chavali, Istio Networking Working Group lead and Software Engineering Architect at Salesforce
{{< /quote >}}

## Continuous technical innovation

We are firm believers that diversity drives innovation. What amazes us most is the continuous innovation from the
Istio community, from making upgrades easier, to adopting Kubernetes Gateway API, to adding the new sidecar-less
ambient data plane mode, to making Istio easy to use and as transparent as possible.

Istio’s ambient mode was introduced in September 2022, designed for simplified
operations, broader application compatibility, and reduced infrastructure cost. Ambient mode introduces
lightweight, shared Layer 4 (L4) node proxies and optional Layer 7 (L7) proxies, removing the need for traditional
sidecar proxies from the data plane. The core innovation behind ambient mode is that it slices the L4 and L7
processing into two distinct layers. This layered approach allows you to adopt Istio incrementally, enabling a
smooth transition from no mesh, to a secure overlay (L4), to optional full L7 processing — on a per-namespace
basis, as needed, across your fleet.

As part of the [Istio 1.22 release](/news/releases/1.22.x/announcing-1.22/), [ambient mode has reached beta](/blog/2024/ambient-reaches-beta/)
and you can run Istio without sidecars in production with precautions.

Here are some thoughts and well-wishes from our contributors and users:

{{< quote >}}
**Auto Trader has been using Istio in production, since before it was ready for production! It's significantly
improved our operational capabilities, standardizing the way we secure, configure, and monitor our services. Upgrades have evolved from daunting tasks to almost
non-events, and the introduction of Ambient is evidence of the continued commitment to simplification – making it
easier than ever for new users to get real value with minimal effort.**

— Karl Stoney, Technical Architect at AutoTrader UK
{{< /quote >}}

{{< quote >}}
**Istio is a core component of the cloud native stack for Akamai's Cloud, providing a secure service mesh for
products and services delivering millions of RPS and hundreds of Gigabytes of throughput per cluster. We look forward to the future roadmap for the project and are excited
to evaluate new features such as the Ambient Mesh later this year.**

— Alex Chircop, Chief Product Architect at Akamai
{{< /quote >}}

{{< quote >}}
**Istio's networking and security capabilities have become a fundamental component of our infrastructure operations. The introduction of Istio's ambient mode has significantly simplified management and
reduced the size of our Kubernetes cluster nodes by approximately 20%. We successfully migrated our production
system to use the ambient data plane.**

— Saarko Eilers, Infrastructure Operations Manager at EISST International Ltd
{{< /quote >}}

{{< quote >}}
**Happy birthday to Istio! It has been an honor to be a part of the great community over
the years, especially as we continue to build the world’s best service mesh with ambient mode.**

— John Howard, the most prolific Istio contributor, Istio Technical Oversight Committee member, and Senior Architect at Solo.io
{{< /quote >}}

{{< quote >}}
**It’s great to see a mature project like Istio continue to evolve and flourish. Becoming a graduated CNCF project has attracted a
wave of new developers contributing to its continued success.  Meanwhile ambient mesh and Gateway API support
promises to usher in a new era of service mesh adoption.  I’m excited to see what’s to come!**

— Justin Pettit, Istio Steering Committee member and Senior Staff Engineer at Google
{{< /quote >}}

{{< quote >}}
**Happy birthday to the incredible Istio project that has not only revolutionized the way we approach service mesh
technology but has also cultivated a vibrant and inclusive community! Witnessing Istio's evolution from a CNCF incubating project to a graduated
project has been remarkable. The recent release of Istio 1.22 underscores its continuous growth and commitment to
excellence, offering enhanced features and improved performance. Looking forward to the next big step for the project.**

— Iris Ding, Istio Steering Committee member and Software Engineer at Intel
{{< /quote >}}

{{< quote >}}
**It’s been a privilege to be part of the Istio project from the start, seeing it and the community mature and grow over the years. On a personal note, Istio has been central to my own career for the past eight years! I firmly believe that the best of Istio is yet to come, and in the coming years we’ll see continued growth, maturity, and adoption. Cheers to the wonderful community for reaching this milestone together.**

— Zack Butcher, Istio Steering Committee member and Founding & Principal Engineer at Tetrate
{{< /quote >}}

## Learn more about Istio

If you are new to Istio, here are a few resources to help you learn more:

- Check out the [project website](https://istio.io) and [GitHub repository](https://github.com/istio/istio/).
- Read the [documentation](/docs/).
- Join the community [Slack](https://slack.istio.io/).
- Follow the project on [Twitter](https://twitter.com/IstioMesh) and [LinkedIn](https://www.linkedin.com/company/istio).
- Attend the [user community meetings](https://github.com/istio/community/blob/master/README.md#community-meeting).
- Join the [working group meeting](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings).
- Become an Istio contributor and developer by submitting a [membership request](https://github.com/istio/community/blob/master/ROLES.md#member), after you have a pull request merged.

If you are already part of the Istio community, please wish the Istio project a happy 7th birthday, and share your
thoughts about the project on social media. Thank you for your help and support!
