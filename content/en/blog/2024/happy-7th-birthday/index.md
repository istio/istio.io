---
title: "Happy 7th Birthday, Istio!"
description: We are excited about Istio’s momentum and exciting future.
publishdate: 2024-05-24
attribution: "Lin Sun (Solo.io), for the Istio Steering Committee"
keywords: [istio,birthday,momentum,future]
---

{{< image width="100%"
    link="./7th-birthday.png"
    alt="Happy 7th birthday, Istio!"
    >}}

On this day in 2017, [Google and IBM announced the launch of the Istio service mesh](https://techcrunch.com/2017/05/24/google-ibm-and-lyft-launch-istio-an-open-source-platform-for-managing-and-securing-microservices/). [Istio](https://istio.io/) is an open technology that enables developers to seamlessly connect, manage, and secure networks of different microservices — regardless of platform, source, or vendor. We can hardly believe that Istio turns seven today! To celebrate the project’s 7th birthday, we wanted to highlight Istio’s momentum and its exciting future.

## Rapid adoption among users

Istio, the most widely adopted service mesh project in the world, has been gathering significant momentum since its inception in 2017. Last year Istio joined Kubernetes, Prometheus, and other stalwarts of the cloud native ecosystem with [its CNCF graduation] (https://www.cncf.io/announcements/2023/07/12/cloud-native-computing-foundation-reaffirms-istio-maturity-with-project-graduation/). End users range from digital native startups to the world’s largest financial institutions and telcos, with [case studies](https://istio.io/latest/about/case-studies/) from companies including eBay, T-Mobile, Airbnb, Splunk, FICO, T-Mobile, Salesforce.com, and many others.

Istio’s control plane and sidecar are the #3 and #4 most downloaded images on DockerHub, each with over [10 billion downloads](https://hub.docker.com/search?q=istio).

{{< image width="100%"
    link="./dockerhub.png"
    alt="DockerHub downloads of Istio!"
    >}}

We have over 35k Github stars on [Istio’s main repository](https://github.com/istio/istio/), with continuing growth. Thank you everyone who starred the istio/istio repo.

{{< image width="100%"
    link="./github-stars.png"
    alt="GitHub stars of the istio/istio repo!"
    >}}


We asked a few of our users for their thoughts on the occasion of Istio’s 7th birthday:

"Today, Istio serves as the backbone of Airbnb's service mesh, managing all our traffic between hundreds of thousands of workloads,” said Weibo He, Senior Staff Software Engineer at Airbnb. “Five years since adopting Istio, we've always been happy with that decision. It's truly amazing to be part of this vibrant and supportive community. Happy Birthday, Istio!" 

"Istio has powered our ability to rapidly deploy and test microservices in a production-like, isolated environment along with the dependent services,” said Sudheendra Murthy, Principal Engineer & Service Mesh Architect at eBay. “This approach, known as Isolates, enables eBay's developers to identify defects earlier in the development lifecycle, increase the stability of live environments by reducing flakiness, and build confidence in automated production deployments. Ultimately, this has accelerated the development process and improved the success rate of production deployments."

"Istio enhances the security of our cloud platform while simplifying observability by integrating distributed tracing and OpenTelemetry,” said Sathish Krishnan, Distinguished Engineer at UBS. “This combination provides robust security features and deep insights into system performance, enabling more effective monitoring and troubleshooting of our distributed services."

“Adopting Istio has been a game changer for our engineering organization in our journey of adopting a microservices based architecture,” said Sjray Kumar, Principal Software Engineer at Bluecore. “Its *batteries included* approach has allowed us to easily manage traffic routing, gain deep visibility into our service to service interactions with distributed tracing, and extensibility via WASM plugins. Its comprehensive feature set has made it an essential part of our infrastructure, and has allowed our engineers to decouple application code from infrastructure plumbing.”

“Istio is amazing, I've been using it for 4 to 5 years and found it very comfortable to manage thousands of gateways for tens of thousands of pods with very low latency,” said Ezequiel Arielli, Head of Cloud Platform at SIGMA Financial AI. “If you need to set up a very secure infrastructure, Istio is a great friend. Also, it's excellent for infrastructures that demand a lot of security and need to be aligned with PCI/HIPAA/SoC2 standards.”

“Istio helps us secure our environments in a standardized way across all our deployments for our various customers,” said Joel Millage, Software Engineer at BCubed. “The flexibility and customization of Istio really helps us build better applications by delegating encryption, authorization, and authentication to the service mesh and not having to implement that across our application code base.”

“We use Istio at Predibase extensively to simplify communication between our multi-cluster mesh that helps deploy and train open source fine-tuned LLM models with low latency and failover,” said Gyanesh Mishra, Cloud Infrastructure Engineer at Predibase. “With Istio, we get a lot of out of the box functionality that would otherwise take us weeks to implement.”

“Istio is without a doubt the most complete and feature full Service Mesh platform on the market,” said Daniel Requena, SRE at iFood. “This success is the direct result of an engaged community that helps itself and is always included in the project directions. Congratulations on the anniversary, Istio!”

“We've been using Istio in production for years now, it’s a key component of our infrastructure allowing us to securely connect micro-services, and provide ingress/egress traffic management and 1st class observability,” said Frédéric Gaudet, Senior SRE at BlablaCar. “The community is great and each release brings a lot of exciting features."

## Amazing diversity across end users and vendors

Over the past year, our community has observed tremendous growth in terms of both the number of contributing companies and the number of contributors. Recall that Istio had 500 contributors when Istio turned three years old? Istio now has had over 1,700 contributors in the past year. With the Microsoft Open Service Mesh team joining the Istio community, we are now the preferred service mesh not only for Google Cloud, Red Hat OpenShift, and VMware Tanzu, but also for Azure. We are also delighted to see the Amazon Web Service team publish the [EKS Blueprint for Istio](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/) due to high demand from users wanting to run Istio on AWS.

Below are the top contributing companies for the past year, with Solo.io, Google, and DaoCloud being the top three. While most of these companies are Istio vendors, Salesforce and Ericsson are end users running Istio in production!

{{< image width="100%"
    link="./contribution.png"
    alt="Top Istio contributing companies for the past year!"
    >}}

Here are some thoughts from community leaders:

“Service mesh adoption has been steadily rising over the past few years as cloud native adoption has matured across industries,” said Chris Aniszczyk, CTO of CNCF. “Istio has helped drive part of this maturation since they graduated last year in CNCF and we wish them a fantastic birthday. We look forward to watching and supporting this continued growth as the Istio team adds new features like ambient mode and simplifies the service mesh experience.”

“Service Meshes are core to microservice architectures, a hallmark of cloud native,” said Emily Fox, CNCF TOC chair and Senior Principal Software Engineer at Red Hat. “Istio's birthday celebrates the proliferation and importance not only of observability and traffic management, but the increasing demand for secure-by-default communications through encryption, mutual authentication, and many other core security tenets that simplify the adoption, integration, and deployment experience.”

“In my opinion Istio isn’t a service mesh. It’s a collaborative community of users and contributors who happen to deliver the world’s most popular service mesh,” said Mitch Connors, Istio Technical Oversight Committee member and Principal Engineer at Microsoft. “Happy birthday to this amazing community! It’s been a fantastic seven years, and I’m looking forward to celebrating many more with my friends and colleagues from around the world in the Istio community!”

“It has been a privilege and a fulfilling experience to be part of the world's most popular service mesh team for the past two years,” Faseela K, Istio Steering Committee Member and Cloud Native Developer at Ericsson. “Happy to see Istio grow from a CNCF incubating to graduated project, and even happier to see the momentum and passion with which the latest and greatest 1.22 release was done. Wishing many more successful releases in the coming years.”

“It has been a privilege to have worked with the Istio community over the last 5 years. There has been an abundance of contributors whose dedication, passion, and hard work have made my time on the project truly enjoyable,” said Eric Van Norman, Istio Technical Oversight Committee member and Advisory Software Engineer at IBM. “The community has many users who provide feedback to help make Istio the best service mesh. I continue to be amazed by what the community does, and look forward to seeing what successes we will have in the future.”

“What makes Istio unique is the community full of developers, users, and vendors from all across the globe working together to make Istio the best and most powerful open service mesh in the industry,” said Neeraj Poddar, Istio Technical Oversight Committee member and VP of Engineering at Solo.io. “It’s the strength of the community that has made Istio so successful and now under CNCF I look forward to seeing Istio as the de facto service mesh standard for all cloud native applications.”

## Continuous Technical Innovation

We are firm believers that diversity drives innovation. What amazes me most is the continuous innovation from the Istio community, from making upgrades easier, to adopting Kubernetes Gateway API, to adding the new sidecar-less data plane mode called ambient, to making Istio easy to use and as transparent as possible. Istio’s ambient mode was launched in September 2022, introducing a new data plane mode without sidecars that’s designed for simplified operations, broader application compatibility, and reduced infrastructure cost. Ambient mode introduces lightweight, shared Layer 4 (L4) node proxies and optional Layer 7 (L7) proxies, removing the need for traditional sidecar proxies from the data plane. The core innovation behind ambient mode is that it slices the L4 and L7 processing into two distinct layers. This layered approach allows you to adopt Istio incrementally, enabling a smooth transition from no mesh, to a secure overlay (L4), to optional full L7 processing — on a per-namespace basis, as needed, across your fleet. As part of the [Istio 1.22 release](/news/releases/1.22.x/announcing-1.22/), ambient mode reaches [beta](/blog/2024/ambient-reaches-beta/) and you can run Istio without sidecars in production with precautions.

Here are some thoughts and well-wishes from our contributors and users:

"Auto Trader has been using Istio in production, since before it was ready for production! It's significantly improved our operational capabilities, standardizing the way we secure, configure, and monitor our services,” said Karl Stoney, Technical Architect at AutoTracker UK. “Upgrades have evolved from daunting tasks to almost non-events, and the introduction of Ambient is evidence of the continued commitment to simplification – making it easier than ever for new users to get real value with minimal effort."

“Istio is a core component of the cloud native stack for Akamai's Cloud, providing a secure service mesh for products and services delivering millions of RPS and hundreds of Gigabytes of throughput per cluster,” said Alex Chircop, Chief Product Architect at Akamai. “We look forward to the future roadmap for the project and are excited to evaluate new features such as the Ambient Mesh later this year.”

“We are now running Istio ambient mode in production. Istio's networking and security capabilities have become a fundamental component of our infrastructure operations,” said Saarko Eilers, Infrastructure Operations Manager at EISST International Ltd. “The introduction of Istio's ambient mode has significantly simplified management and reduced the size of our Kubernetes cluster nodes by approximately 20%. We successfully migrated our production system to use the ambient dataplane.”
(logo: https://quodarca-assets.fra1.digitaloceanspaces.com/df289f0fa491075c29a18766b38ea5bd.png)

“It’s great to see a mature project like Istio continue to evolve and flourish,” said Justin Pettit, Istio Steering Committee Member and Senior Staff Engineer at Google. “Becoming a graduated CNCF project has attracted a wave of new developers contributing to its continued success.  Meanwhile ambient mesh and Gateway API support promises to usher in a new era of service mesh adoption.  I’m excited to see what’s to come!”

“Happy birthday to Istio!” said John Howard, the most prolific Istio contributor, Istio Technical Oversight Committee member, and Senior Architect at Solo.io. “It has been an honor to be a part of the great community over the years, especially as we continue to build the world’s best service mesh with Ambient mode.”

“Happy birthday to the incredible Istio project that has not only revolutionized the way we approach service mesh technology but has also cultivated a vibrant and inclusive community!” said Iris Ding, Istio Steering Committee Member and Software Engineer at Intel. “Witnessing Istio's evolution from a CNCF incubating project to a graduated project has been remarkable. The recent release of Istio 1.22 underscores its continuous growth and commitment to excellence, offering enhanced features and improved performance. Looking forward to the next big step for the project.”

## Learn more about Istio

If you are new to Istio, here are a few resources to help you learn more:

- Check out the [project website](https://istio.io) and [GitHub repository](https://github.com/istio/istio/).
- Read the [documentation](https://istio.io/latest/docs/).
- Join the community [Slack](https://slack.istio.io/).
- Follow the project on [Twitter](https://twitter.com/IstioMesh) and [LinkedIn](https://www.linkedin.com/company/istio).
- Attend the [user community meetings](https://github.com/istio/community/blob/master/README.md#community-meeting).
- Join the [working group meeting](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings). 
- Become an Istio contributor and developer by submitting a [membership request](https://github.com/istio/community/blob/master/ROLES.md#member), after you have a pull request merged.

If you are already part of the Istio community, please wish the Istio project a happy 7th birthday, and share your thoughts about the project on social media. Thank you for your help and support!
