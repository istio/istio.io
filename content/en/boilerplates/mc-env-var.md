---
---
To simplify the deployment instructions and use the examples provided, set the
following environment variables. If you use your own string values, ensure they
are viable as filenames and compatible with `Makefiles`. Go to the [GNU guide](https://www.gnu.org/software/make/manual/html_node/Rule-Syntax.html)
for more information.

The guide assumes that the following environment variables are set:

<table>
   <thead>
      <tr>
      <th><strong>Environment Variable</strong></th>
      <th><strong>Description</strong></th>
      </tr>
   </thead>
      <tbody>
      <tr>
         <td>ISTIO</td>
         <td>The top-level directory of the Istio installation.</td>
      </tr>
      <tr>
         <td>CLUSTER_1</td>
         <td>The name of the first cluster. The guide uses <code>cluster1</code>.</td>
         </tr>
      <tr>
         <td>CLUSTER_2</td>
         <td>The name of the second cluster. Must be different from the value in
         <code>CLUSTER_1</code>. The guide uses <code>cluster2</code>.</td>
         </tr>
      <tr>
         <td>CTX_1</td>
         <td>The path to the Kubernetes context file for the first cluster.</td>
      </tr>
      <tr>
         <td>CTX_2</td>
         <td>The path to the Kubernetes context file for the second cluster.</td>
      </tr>
      <tr>
         <td>NETWORK_1</td>
         <td>The name of the first network. The guide uses <code>network1</code>.</td>
      </tr>
      <tr>
         <td>MESH</td>
         <td>The common mesh ID to use for all clusters in the mesh, for example
         sample-mesh.</td>
      </tr>
      <tr>
         <td>DISCOVERY_ADDRESS</td>
         <td>Stores the IP address of the Istio ingress gateway of your first cluster,
         <code>Cluster_1</code>.</td>
      </tr>
   </tbody>
</table>
