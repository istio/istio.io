---
title: Istio
description: Connect, secure, control, and observe services.
---
<!-- these script blocks are only for the primary English home page -->
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "Organization",
        "url": "https://istio.io",
        "logo": "https://istio.io/img/logo.png",
        "sameAs": [
            "https://twitter.com/IstioMesh",
            "https://discuss.istio.io/"
        ]
    }
</script>
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "WebSite",
        "url": "https://istio.io/",
        "potentialAction": {
            "@type": "SearchAction",
            "target": "https://istio.io/search.html?q={search_term_string}",
            "query-input": "required name=search_term_string"
        }
    }
</script>

<main class="landing">
    <div id="banner">
        {{< inline_image "landing/istio-logo.svg" >}}
        <div id="hero-text">
            <h1 id="hero-label">Istio</h1>
            <h1 id="hero-lead">Connect, secure, control, and observe services.
        </div>
    </div>

    <div id="panels">
        <div id="panel1" class="panel">
            <a href="/docs/concepts/traffic-management/">
                <div class="panel-img-top">
                    {{< inline_image "landing/routing-and-load-balancing.svg" >}}
                </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">Connect</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        Intelligently control the flow of traffic and API calls between services, conduct a range of tests, and upgrade gradually with
                        red/black deployments.
                    </p>
                </div>
            </a>
        </div>

        <div id="panel2" class="panel">
            <a href="/docs/concepts/security/">
                <div class="panel-img-top">
                    {{< inline_image "landing/resiliency.svg" >}}
                </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">Secure</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        Automatically secure your services through managed authentication, authorization, and encryption of communication between
                        services.
                    </p>
                </div>
            </a>
        </div>

        <div id="panel3" class="panel">
            <a href="/docs/concepts/policies-and-telemetry/">
                <div class="panel-img-top">
                    {{< inline_image "landing/policy-enforcement.svg" >}}
                </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">Control</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        Apply policies and ensure that they’re enforced, and that resources are fairly distributed among consumers.
                    </p>
                </div>
            </a>
        </div>

        <div id="panel4" class="panel">
            <a href="/docs/concepts/policies-and-telemetry/">
                <div class="panel-img-top">
                    {{< inline_image "landing/telemetry-and-reporting.svg" >}}
                </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">Observe</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        See what's happening with rich automatic tracing, monitoring, and logging of all your services.
                   </p>
                </div>
            </a>
        </div>
    </div>

    <div id="buttons">
        <a title="Install Istio on Kubernetes today." class="btn" href="/docs/setup/kubernetes/">GET STARTED</a>
        <a title="Dive deeper to understand what Istio is and how it works." class="btn" href="/docs/concepts/what-is-istio/">LEARN MORE</a>
        <a title="Download the latest release." class="btn" href="{{< istio_release_url >}}">DOWNLOAD {{< istio_release_name >}}</a>
    </div>
</main>
