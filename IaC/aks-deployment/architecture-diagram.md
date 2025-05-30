# AKS Lab Architecture Diagram

```
                                       +-------------------------------+
                                       |                               |
                                       |  Azure Container Registry     |
                                       |  (ACR)                        |
                                       |                               |
                                       +--------------+----------------+
                                                     |
                                                     | Pull Images
                                                     v
+----------------------------------+   +-------------+-----------------+   +------------------------------+
|                                  |   |                               |   |                              |
|  Azure Key Vault                 |   |  Azure Kubernetes Service     |   |  Azure App Configuration     |
|  - Secrets                       +<--+  (AKS)                        +-->+  - Feature Flags             |
|  - Certificates                  |   |  - KEDA                       |   |  - Configuration Settings    |
|  - Keys                          |   |  - Workload Identity          |   |                              |
|                                  |   |  - VPA                        |   |                              |
+------------------+---------------+   |  - Web Application Routing    |   +------------------------------+
                   ^                   |  - CNI Overlay (Cilium)       |
                   |                   |                               |
                   |                   +------------+--------+---------+
                   |                                |        ^
                Secure                              |        |
                Access                              v        |
                                    +---------------+--------+--------+   +------------------------------+
                                    |                                 |   |                              |
                                    |  Azure Cosmos DB (MongoDB API)  |   |  Azure Monitor & Insights    |
                                    |  - Serverless                   |   |  - Log Analytics             |
                                    |  - NoSQL Database               |   |  - Prometheus                |
                                    |                                 |   |  - Grafana                   |
                                    +---------------------------------+   |  - Container Insights        |
                                                                          |                              |
                                                                          +------------------------------+

```

## Key Components

1. **Azure Kubernetes Service (AKS)**
   - Core container orchestration platform
   - Includes workload identity, VPA, KEDA, Azure CNI with Cilium
   - Web Application Routing add-on for ingress

2. **Azure Container Registry (ACR)**
   - Private container repository
   - Integrated with AKS pull access

3. **Azure Key Vault**
   - Secure management of secrets and certificates
   - RBAC authorization
   - Workload Identity access

4. **Azure Cosmos DB (MongoDB API)**
   - Serverless NoSQL database
   - MongoDB API compatible

5. **Azure App Configuration**
   - Feature flags management
   - Application settings

6. **Azure Monitor & Insights**
   - Log Analytics workspace
   - Prometheus metrics
   - Grafana dashboards
   - Container Insights with enhanced metrics

## Data & Authentication Flows

- AKS pods authenticate to Azure services using Workload Identity
- Container Registry provides images to AKS
- Applications access Cosmos DB using MongoDB API
- Key Vault secures sensitive information
- App Configuration provides runtime configuration
- All components emit logs to Azure Monitor
