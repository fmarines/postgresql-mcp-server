# PostgreSQL MCP Server Helm Chart

This Helm chart deploys the PostgreSQL MCP (Model Context Protocol) Server on Kubernetes, providing comprehensive PostgreSQL database management capabilities for AI assistants.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PostgreSQL database (accessible from the cluster)
- PV provisioner support in the underlying infrastructure (optional)

## Installing the Chart

### Quick Start

```bash
# Add the helm chart repository (if published)
helm repo add postgresql-mcp /path/to/helm-chart
helm repo update

# Install with default configuration
helm install my-postgres-mcp postgresql-mcp/postgresql-mcp-server \
  --set postgresql.connectionString="postgresql://user:password@host:5432/database"
```

### Install from Local Chart

```bash
# From the project root directory
helm install my-postgres-mcp ./helm-chart \
  --set postgresql.host=postgresql \
  --set postgresql.port=5432 \
  --set postgresql.database=mydb \
  --set postgresql.username=myuser \
  --set postgresql.password=mypassword
```

### Using Existing Secret

```bash
# Create a secret with your PostgreSQL connection string
kubectl create secret generic postgres-mcp-secret \
  --from-literal=POSTGRES_CONNECTION_STRING="postgresql://user:password@host:5432/database"

# Install using the existing secret
helm install my-postgres-mcp ./helm-chart \
  --set postgresql.existingSecret=postgres-mcp-secret
```

### With Custom Values File

```bash
helm install my-postgres-mcp ./helm-chart -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters of the PostgreSQL MCP Server chart and their default values.

### Core Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `henkey/postgres-mcp` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### PostgreSQL Connection

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.connectionString` | Full PostgreSQL connection string | `""` |
| `postgresql.existingSecret` | Existing secret (same namespace) with connection string | `""` |
| `postgresql.existingSecretPasswordKey.name` | Secret name (same namespace) containing password | `""` |
| `postgresql.existingSecretPasswordKey.key` | Key in secret containing password | `"postgres-password"` |
| `postgresql.host` | PostgreSQL host | `postgresql` |
| `postgresql.port` | PostgreSQL port | `5432` |
| `postgresql.database` | Database name | `postgres` |
| `postgresql.username` | Database username | `postgres` |
| `postgresql.password` | Database password | `""` |
| `postgresql.sslMode` | SSL mode | `prefer` |

**Connection Options (in order of precedence):**
1. **Full Connection String Secret**: Use `postgresql.existingSecret` pointing to a secret (in same namespace) with `POSTGRES_CONNECTION_STRING` key
2. **Password from Existing Secret**: Use `postgresql.existingSecretPasswordKey` to reference a secret (in same namespace) containing only the password - common when PostgreSQL is deployed separately
3. **Values-based**: Provide connection details directly in values (not recommended for production)

**Note:** All secrets must exist in the **same namespace** as the MCP server deployment. Kubernetes does not support cross-namespace secret references for security reasons.

### Tools Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tools.enabled` | Enable tools configuration | `true` |
| `tools.enabledTools` | List of enabled tool names (empty = all) | `[]` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable autoscaling | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `5` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `80` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target Memory % | `80` |

### Security

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podSecurityContext.runAsNonRoot` | Run as non-root user | `true` |
| `podSecurityContext.runAsUser` | User ID | `1001` |
| `podSecurityContext.fsGroup` | Group ID | `1001` |
| `securityContext.readOnlyRootFilesystem` | Read-only root filesystem | `true` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name | `""` |
| `serviceAccount.annotations` | Service account annotations | `{}` |

### Network Policy

| Parameter | Description | Default |
|-----------|-------------|---------|
| `networkPolicy.enabled` | Enable network policy | `false` |
| `networkPolicy.policyTypes` | Policy types | `["Ingress", "Egress"]` |

## Example Configurations

### Basic Deployment

```yaml
# values-basic.yaml
postgresql:
  host: my-postgresql-service
  port: 5432
  database: production
  username: app_user
  password: secure_password

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 256Mi
```

```bash
helm install postgres-mcp ./helm-chart -f values-basic.yaml
```

### Using Existing PostgreSQL Secret (Same Namespace)

When PostgreSQL is deployed in the same namespace, reference its secret:

```yaml
# values-existing-secret.yaml
postgresql:
  # Reference the PostgreSQL secret (must be in same namespace)
  existingSecretPasswordKey:
    name: "postgresql"  # Secret name (e.g., created by bitnami/postgresql)
    key: "postgres-password"  # Key name in the secret
  
  # Connection details (password pulled from secret)
  host: "postgresql"  # Service name in same namespace
  port: 5432
  database: "myapp"
  username: "postgres"
  sslMode: "require"

replicaCount: 2

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
```

```bash
# Install PostgreSQL first (in same namespace)
helm install postgresql bitnami/postgresql \
  --namespace default \
  --set auth.database=myapp

# Install PostgreSQL MCP Server (same namespace)
helm install postgres-mcp ./helm-chart \
  --namespace default \
  -f values-existing-secret.yaml

# IMPORTANT: Both deployments must be in the same namespace!
```

### High Availability with Autoscaling

```yaml
# values-ha.yaml
replicaCount: 2

postgresql:
  existingSecret: postgres-credentials

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 75

podDisruptionBudget:
  enabled: true
  minAvailable: 1

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

```bash
helm install postgres-mcp-ha ./helm-chart -f values-ha.yaml
```

### Restricted Tools Configuration

```yaml
# values-restricted.yaml
postgresql:
  connectionString: "postgresql://user:pass@host:5432/db"

tools:
  enabled: true
  enabledTools:
    - postgres_analyze_database
    - postgres_manage_schema
    - postgres_execute_query
    - postgres_execute_mutation
    - postgres_manage_indexes

resources:
  limits:
    cpu: 500m
    memory: 512Mi
```

```bash
helm install postgres-mcp-restricted ./helm-chart -f values-restricted.yaml
```

### Secure Production Deployment

```yaml
# values-production.yaml
replicaCount: 3

image:
  pullPolicy: Always
  tag: "1.0.5"

postgresql:
  existingSecret: postgres-prod-credentials
  sslMode: require

podDisruptionBudget:
  enabled: true
  minAvailable: 2

networkPolicy:
  enabled: true
  egress:
    - to:
      - podSelector:
          matchLabels:
            app: postgresql
      ports:
      - protocol: TCP
        port: 5432

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1001

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

```bash
helm install postgres-mcp-prod ./helm-chart -f values-production.yaml --namespace production
```

## Deploying on Rancher

### Method 1: Rancher UI

1. **Access Rancher UI**
   - Navigate to your Rancher dashboard
   - Select your target cluster

2. **Install via Apps & Marketplace**
   - Go to **Apps** → **Charts**
   - Click **Install** → **Import Helm Chart**
   - Upload the chart directory or provide Git repository URL

3. **Configure Values**
   - Fill in PostgreSQL connection details
   - Adjust resource limits as needed
   - Configure autoscaling if desired

4. **Deploy**
   - Click **Install** to deploy the chart
   - Monitor deployment in **Workloads** section

### Method 2: Rancher CLI

```bash
# Login to Rancher
rancher login https://your-rancher-url --token your-token

# Select your cluster
rancher context switch

# Install the chart
rancher app install postgresql-mcp-server postgres-mcp \
  --namespace default \
  --set postgresql.host=postgresql \
  --set postgresql.password=yourpassword
```

### Method 3: kubectl with Rancher

```bash
# Get kubeconfig from Rancher
# In Rancher UI: Cluster → Kubeconfig File → Copy to Clipboard

# Save to file
export KUBECONFIG=~/rancher-kubeconfig.yaml

# Install using helm
helm install postgres-mcp ./helm-chart \
  --namespace mcp-system \
  --create-namespace \
  -f production-values.yaml
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade my-postgres-mcp ./helm-chart \
  --set image.tag=1.0.6 \
  --reuse-values

# Upgrade with new values file
helm upgrade my-postgres-mcp ./helm-chart -f new-values.yaml
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall my-postgres-mcp

# Uninstall and delete namespace
helm uninstall my-postgres-mcp -n mcp-system
kubectl delete namespace mcp-system
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=postgresql-mcp-server
kubectl describe pod <pod-name>
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=postgresql-mcp-server --tail=100 -f
```

### Test PostgreSQL Connection

```bash
# Exec into the pod
kubectl exec -it <pod-name> -- /bin/sh

# Test connection (if psql is available)
psql "$POSTGRES_CONNECTION_STRING" -c "SELECT version();"
```

### Common Issues

1. **Connection Refused**: Check PostgreSQL host/port and network policies
2. **Authentication Failed**: Verify credentials in secret
3. **Pod CrashLoopBackOff**: Check logs for connection string format errors
4. **Permission Denied**: Ensure PostgreSQL user has required permissions

## Values File Examples

See the `examples/` directory for complete values file templates:
- `values-development.yaml` - Development environment
- `values-staging.yaml` - Staging environment
- `values-production.yaml` - Production environment

## Contributing

1. Fork the repository
2. Make your changes
3. Test the chart: `helm lint ./helm-chart`
4. Submit a pull request

## License

AGPLv3 License - see LICENSE file for details.

## Support

- Documentation: https://github.com/HenkDz/postgresql-mcp-server
- Issues: https://github.com/HenkDz/postgresql-mcp-server/issues
