---
title: Sidecar 还是 Ambient？
description: 了解 Istio 的两种数据平面模式以及您应该使用哪一种。
weight: 30
keywords: [sidecar, ambient]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Istio 服务网格在逻辑上分为数据平面和控制平面。

{{< gloss "data plane" >}}数据平面{{< /gloss >}}是一组代理，用于调解和控制微服务之间的所有网络通信。
这些代理还可以收集和报告所有网格流量的可观测数据。

{{< gloss "control plane" >}}控制平面{{< /gloss >}}管理和配置数据平面中的这些代理。

Istio 支持两种主要的{{< gloss "data plane mode">}}数据平面模式{{< /gloss >}}：

* **Sidecar 模式**，此模式会为集群中启动的每个 Pod 都部署一个 Envoy 代理，
  或者与在虚拟机上运行的服务并行运行一个 Envoy 代理。
* **Ambient 模式**，此模式在每个节点上使用四层代理，
  另外可以选择为每个命名空间使用一个 Envoy 代理来实现七层功能。

您可以选择将某些命名空间或工作负载纳入任一模式。

## Sidecar 模式 {#sidecar=mode}

Istio 自 2017 年首次发布以来就基于 Sidecar 模式构建。
Sidecar 模式易于理解且经过彻底的实战测试，但需要花费资源成本和运营开销。

* 您部署的每个应用都有一个 Envoy 代理{{< gloss "injection" >}}被注入{{< /gloss >}}作为 Sidecar
* 所有代理都可以处理四层和七层流量

## Ambient 模式 {#ambient-mode}

Ambient 模式于 2022 年推出，旨在解决 Sidecar 模式用户报告的缺点。
从 Istio 1.22 开始，它在单集群使用场景就达到生产就绪状态。

* 所有流量都通过仅支持四层的节点代理进行代理
* 应用可以选择通过 Envoy 代理进行路由，以获得七层功能

## 在 Sidecar 和 Ambient 之间做出选择 {#choosing-between-sidecar-and-ambient}

用户通常首先部署网格以实现零信任安全态势，然后根据需要选择性地启用 L7 功能。
Ambient 网格允许这些用户在不需要 L7 功能时完全绕过 L7 处理的成本。

<table>
  <thead>
    <tr>
      <td style="border-width: 0px"></td>
      <th><strong>Sidecar</strong></th>
      <th><strong>Ambient</strong></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>流量管理</th>
      <td>完整的 Istio 功能集</td>
      <td>完整的 Istio 功能集（需要使用 waypoint）</td>
    </tr>
    <tr>
      <th>安全</th>
      <td>完整的 Istio 功能集</td>
      <td>完整的 Istio 功能集：Ambient 模式下具备加密和 L4 鉴权。需要 waypoint 才能进行 L7 鉴权。</td>
    </tr>
    <tr>
      <th>可观测性</th>
      <td>完整的 Istio 功能集</td>
      <td>完整的 Istio 功能集：Ambient 模式下具备 L4 遥测；使用 waypoint 实现 L7 可观测性</td>
    </tr>
    <tr>
      <th>可扩展性</th>
      <td>完整的 Istio 功能集</td>
      <td>完整的 Istio 功能集（需要使用 waypoint）<sup><a href="#supported-features">&alpha;</a></sup></td>
    </tr>
    <tr>
      <th>向网格添加工作负载</th>
      <td>为命名空间添加标签并重启所有 Pod 以添加 Sidecar</td>
      <td>为命名空间添加标签 - 无需重启 Pod</td>
    </tr>
    <tr>
      <th>递增式部署</th>
      <td>二进制：Sidecar 是否已被注入</td>
      <td>渐进式：L4 始终开启，L7 可通过配置添加</td>
    </tr>
    <tr>
      <th>生命周期管理</th>
      <td>代理由应用开发人员管理</td>
      <td>平台管理员</td>
    </tr>
    <tr>
      <th>资源利用率</th>
      <td>浪费；必须考虑到每个单独 Pod 的最糟情况并配置最大的 CPU 和内存资源</td>
      <td>waypoint 代理可以像任何其他 Kubernetes Deployment 一样自动扩缩容。<br>有多个副本的工作负载可以使用同一个 waypoint，而不是每个副本都有自己的 Sidecar。</td>
    </tr>
    <tr>
      <th>平均资源成本</th>
      <td>大</td>
      <td>小</td>
    </tr>
    <tr>
      <th>平均延迟（p90/p99）</th>
      <td>0.63ms-0.88ms</td>
      <td>Ambient：0.16ms-0.20ms<br />waypoint：0.40ms-0.50ms</td>
    </tr>
    <tr>
      <th>L7 处理步骤</th>
      <td>两步（源和目标 Sidecar）</td>
      <td>一步（目标 waypoint）</td>
    </tr>
    <tr>
      <th>大规模配置</th>
      <td>需要对<a href="/zh/docs/ops/configuration/mesh/configuration-scoping/">每个 Sidecar 的范围进行配置</a>以削减配置量</td>
      <td>无需自定义配置即可工作</td>
    </tr>
    <tr>
      <th>支持“服务器优先”协议</th>
      <td><a href="/zh/docs/ops/deployment/application-requirements/#server-first-protocols">需要配置</a></td>
      <td>是</td>
    </tr>
    <tr>
      <th>对 Kubernetes Job 的支持</th>
      <td>由于 Sidecar 使用寿命长而变得复杂</td>
      <td>透明支持</td>
    </tr>
    <tr>
      <th>安全模型</th>
      <td>最强：每个工作负载都有自己的密钥</td>
      <td>强：每个节点代理仅具有该节点上工作负载的密钥</td>
    </tr>
    <tr>
      <th>被入侵的应用 Pod<br>可访问网格密钥</th>
      <td>可以</td>
      <td>不可以</td>
    </tr>
    <tr>
      <th>支持</th>
      <td>稳定版，包括多集群</td>
      <td>Beta 版，单集群</td>
    </tr>
    <tr>
      <th>支持的平台</th>
      <td>Kubernetes（任意 CNI）<br />虚拟机</td>
      <td>Kubernetes（任意 CNI）</td>
    </tr>
  </tbody>
</table>

## 四层与七层功能 {#layer-4-vs-layer-7-features}

在七层处理协议的开销远远高于在四层处理网络数据包的开销。
对于给定的服务，如果您的要求可以在 L4 被满足，则可以以明显更低的成本交付服务网格。

### 安全 {#security}

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>加密</th>
      <td>所有 Pod 之间的流量都使用 {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} 加密。</td>
      <td>不适用；Istio 中的服务身份基于 TLS。</td>
    </tr>
    <tr>
      <th>服务到服务的身份验证</th>
      <td>通过 mTLS 证书执行 {{< gloss >}}SPIFFE{{< /gloss >}}。Istio 颁发一个短期 X.509 证书，对 Pod 的服务帐户身份进行编码。</td>
      <td>不适用；Istio 中的服务身份基于 TLS。</td>
    </tr>
    <tr>
      <th>服务到服务的鉴权</th>
      <td>基于网络的鉴权，加上基于身份的策略，例如：
        <ul>
          <li>A 只能接受来自“10.2.0.0/16”的入站调用；</li>
          <li>A 可以调用 B。</li>
        </ul>
      </td>
      <td>完整政策，例如：
        <ul>
          <li>只有使用包含 READ 范围的有效最终用户凭证，A 才能在 B 上执行 GET /foo 操作。</li>
        </ul>
      </td>
    </tr>
    <tr>
      <th>最终用户身份验证</th>
      <td>不适用；我们无法应用每个用户的设置。</td>
      <td>JWT 的本地身份验证，支持通过 OAuth 和 OIDC 流进行远程身份验证。</td>
    </tr>
    <tr>
      <th>最终用户鉴权</th>
      <td>不适用；同上</td>
      <td>可以扩展服务到服务的策略，以要求<a href="/zh/docs/reference/config/security/conditions/">具有特定范围、发行者、主体、受众等的最终用户凭证</a>。<br />可以使用外部鉴权，实现完整的用户到资源的访问，允许根据外部服务的决策来制定每个请求的策略，例如 OPA。</td>
    </tr>
  </tbody>
</table>

### 可观测性 {#observability}

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>日志记录</th>
      <td>基本网络信息：网络 5 元组、发送/接收的字节数等。<a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators">查看 Envoy 文档</a>。</td>
      <td><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators">完整的请求元数据日志记录</a>，外加基本的网络信息。</td>
    </tr>
    <tr>
      <th>链路追踪</th>
      <td>目前还不行，但最终有可能通过 HBONE 实现。</td>
      <td>Envoy 参与分布式链路跟踪。<a href="/zh/docs/tasks/observability/distributed-tracing/overview/">查看 Istio 链路追踪概述</a>。</td>
    </tr>
    <tr>
      <th>指标</th>
      <td>仅 TCP（发送/接收的字节数、数据包数量等）。</td>
      <td>L7 RED 指标：请求率、错误率、请求时间（延迟）。</td>
    </tr>
  </tbody>
</table>

### 流量管理 {#traffic-management}

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>负载均衡</th>
      <td>仅限连接级别。<a href="/zh/docs/tasks/traffic-management/tcp-traffic-shifting/">请参阅 TCP 流量转移任务</a>。</td>
      <td>根据请求，启用例如金丝雀部署、gRPC 流量等。<a href="/zh/docs/tasks/traffic-management/traffic-shifting/">查看 HTTP 流量转移任务</a>。</td>
    </tr>
    <tr>
      <th>熔断</th>
      <td><a href="/zh/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-TCPSettings">仅 TCP</a>。</td>
      <td>除了 TCP 之外，<a href="/zh/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-HTTPSettings">还有 HTTP 设置</a>。</td>
    </tr>
    <tr>
      <th>离群值检测</th>
      <td>当连接建立/失败时。</td>
      <td>请求成功/失败。</td>
    </tr>
    <tr>
      <th>限流</th>
      <td>使用全局限流选项和本地限流选项，<a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/rate_limit_filter#config-network-filters-rate-limit">仅在建立连接时对 L4 连接数据进行限流</a>。</td>
      <td>根据每个请求，<a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rate_limit_filter#config-http-filters-rate-limit">L7 请求元数据的限流</a>。</td>
    </tr>
    <tr>
      <th>超时</th>
      <td>仅建立连接（通过熔断设置来配置保持活跃的连接）。</td>
      <td>按请求。</td>
    </tr>
    <tr>
      <th>重试</th>
      <td>重试建立连接。</td>
      <td>每次请求失败时重试。</td>
    </tr>
    <tr>
      <th>故障注入</th>
      <td>不适用；无法在 TCP 连接上配置故障注入。</td>
      <td>完整的应用和连接级故障（<a href="/zh/docs/tasks/traffic-management/fault-injection/">超时、延迟、特定响应码</a>）。</td>
    </tr>
    <tr>
      <th>流量镜像</th>
      <td>不适用；仅支持 HTTP</td>
      <td><a href="/zh/docs/tasks/traffic-management/mirroring/">按百分比将请求镜像到多个后端</a>。</td>
    </tr>
  </tbody>
</table>

## 不支持的功能 {#unsupported-features}

以下功能在 Sidecar 模式下可用，但尚未在 Ambient 模式下实现：

* Sidecar 与 waypoint 的互操作性
* 多集群安装
* 多网络支持
* 虚拟机支持
