# PostgreSQL MCP Server - Rancher Deployment Guide

Complete guide for deploying the PostgreSQL MCP Server on Rancher using Helm.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Deployment Methods](#deployment-methods)
4. [Configuration](#configuration)
5. [Post-Deployment](#post-deployment)
6. [Troubleshooting](#troubleshooting)
7. [Production Best Practices](#production-best-practices)

## Prerequisites

Before deploying, ensure you have:

- ✅ Rancher 2.x cluster access
- ✅ kubectl configured with cluster access
- ✅ Helm 3.x installed
- ✅ PostgreSQL database accessible from cluster
- ✅ Database credentials ready
- ✅ Appropriate namespace permissions

### Verify Prerequisites

```bash
# Check Rancher cluster connection
kubectl cluster-info

# Verify Helm installation
helm version

# Check namespace access
kubectl auth can-i create deployments --namespace=default
```

## Quick Start

### 1. Create Namespace (Optional)

```bash
# Create dedicated namespace for MCP server
kubectl create namespace mcp-system

# Or via Rancher UI:
# Cluster → Projects/Namespaces → Add Namespace
```

### 2. Create Database Secret

**Option A: Using kubectl**

```bash
# Create secret with connection string
kubectl create secret generic postgres-mcp-secret \
  --namespace=mcp-system \
  --from-literal=POSTGRES_CONNECTION_STRING="postgresql://user:password@host:5432/database?sslmode=prefer"
```

**Option B: Using Rancher UI**

1. Navigate to: **Cluster → Resources → Secrets**
2. Click **Create**
3. Select **Opaque** type
4. Name: `postgres-mcp-secret`
5. Namespace: `mcp-system`
6. Add Key-Value pair:
   - Key: `POSTGRES_CONNECTION_STRING`
   - Value: `postgresql://user:password@host:5432/database`
7. Click **Save**

### 3. Deploy Using Helm

```bash
# Navigate to the helm chart directory
cd /path/to/postgresql-mcp-server/helm-chart

# Install the chart
helm install postgres-mcp . \
  --namespace mcp-system \
  --set postgresql.existingSecret=postgres-mcp-secret \
  --set replicaCount=2
```

### 4. Verify Deployment

```bash
# Check pod status
kubectl get pods -n mcp-system -l app.kubernetes.io/name=postgresql-mcp-server

# View logs
kubectl logs -n mcp-system -l app.kubernetes.io/name=postgresql-mcp-server --tail=50
```

## Deployment Methods

### Method 1: Rancher UI (Recommended for Beginners)

#### Step-by-Step Process

1. **Access Rancher Dashboard**
   - Open Rancher web UI
   - Select your target cluster

2. **Navigate to Apps**
   - Click **Apps** → **Repositories**
   - Add repository (if chart is published) or use local install

3. **Install Application**
   - Go to **Apps** → **Charts**
   - Click **Import YAML**
   - Upload or paste the Helm chart values

4. **Configure Application**
   ```yaml
   # Paste in Rancher UI
   postgresql:
     existingSecret: postgres-mcp-secret
   
   replicaCount: 2
   
   resources:
     limits:
       cpu: 1000m
       memory: 1Gi
     requests:
       cpu: 250m
       memory: 256Mi
   
   autoscaling:
     enabled: true
     minReplicas: 2
     maxReplicas: 5
   ```

5. **Deploy**
   - Click **Install**
   - Monitor deployment in **Workloads** section

### Method 2: Helm CLI (Recommended for Advanced Users)

#### Basic Installation

```bash
# Install with inline values
helm install postgres-mcp ./helm-chart \
  --namespace mcp-system \
  --create-namespace \
  --set postgresql.host=postgresql.database.svc.cluster.local \
  --set postgresql.port=5432 \
  --set postgresql.database=mydb \
  --set postgresql.username=mcpuser \
  --set postgresql.password=secure_password
```

#### Using Values File

```bash
# Use pre-configured values file
helm install postgres-mcp ./helm-chart \
  --namespace mcp-system \
  --create-namespace \
  -f helm-chart/examples/values-rancher.yaml
```

#### With Custom Configuration

```bash
# Create custom values file
cat > my-values.yaml <<EOF
replicaCount: 3

postgresql:
  existingSecret: my-postgres-secret

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
EOF

# Install with custom values
helm install postgres-mcp ./helm-chart \
  --namespace mcp-system \
  --create-namespace \
  -f my-values.yaml
```

### Method 3: Rancher CLI

```bash
# Login to Rancher
rancher login https://rancher.yourdomain.com --token $RANCHER_TOKEN

# Switch to target cluster
rancher context switch

# Install application
rancher app install \
  postgresql-mcp-server postgres-mcp \
  --namespace mcp-system \
  --set postgresql.existingSecret=postgres-mcp-secret \
  --set replicaCount=2
```

## Configuration

### Essential Configuration Options

#### Database Connection

**Method 1: Using Existing Secret (Recommended)**

```yaml
postgresql:
  existingSecret: postgres-mcp-secret
```

**Method 2: Connection Parameters**

```yaml
postgresql:
  host: postgresql.database.svc.cluster.local
  port: 5432
  database: production_db
  username: mcp_user
  password: secure_password
  sslMode: require
```

**Method 3: Full Connection String**

```yaml
postgresql:
  connectionString: "postgresql://user:pass@host:5432/db?sslmode=require&pool_max_conns=10"
```

#### Tools Configuration

**Enable All Tools (Default)**

```yaml
tools:
  enabled: true
  enabledTools: []  # Empty = all tools
```

**Restrict to Specific Tools**

```yaml
tools:
  enabled: true
  enabledTools:
    - postgres_analyze_database
    - postgres_manage_schema
    - postgres_execute_query
    - postgres_execute_mutation
    - postgres_manage_indexes
```

#### Resource Management

**Development Environment**

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

**Production Environment**

```yaml
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

#### High Availability

```yaml
replicaCount: 3

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 75

podDisruptionBudget:
  enabled: true
  minAvailable: 2

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - postgresql-mcp-server
        topologyKey: kubernetes.io/hostname
```

## Post-Deployment

### Verify Installation

```bash
# Check deployment status
kubectl get deployment -n mcp-system

# Check pods
kubectl get pods -n mcp-system -l app.kubernetes.io/name=postgresql-mcp-server

# View recent logs
kubectl logs -n mcp-system -l app.kubernetes.io/name=postgresql-mcp-server --tail=100

# Check events
kubectl get events -n mcp-system --sort-by='.lastTimestamp'
```

### Access Logs in Rancher UI

1. Navigate to **Cluster → Workloads → Deployments**
2. Find `postgresql-mcp-server`
3. Click on pod name
4. Click **View Logs** button
5. Use filters to search logs

### Monitoring

```bash
# Watch pod status
kubectl get pods -n mcp-system -w

# Monitor resource usage
kubectl top pods -n mcp-system

# Check HPA status (if enabled)
kubectl get hpa -n mcp-system
```

### Testing Connectivity

```bash
# Execute into pod
POD_NAME=$(kubectl get pods -n mcp-system -l app.kubernetes.io/name=postgresql-mcp-server -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -n mcp-system -- /bin/sh

# Inside the pod, check environment
echo $POSTGRES_CONNECTION_STRING

# Test connection (if psql available)
# psql "$POSTGRES_CONNECTION_STRING" -c "SELECT version();"
```

## Troubleshooting

### Common Issues

#### 1. Pod CrashLoopBackOff

**Symptoms:**
```bash
$ kubectl get pods -n mcp-system
NAME                                    READY   STATUS             RESTARTS   AGE
postgres-mcp-server-xxx                 0/1     CrashLoopBackOff   5          3m
```

**Solutions:**

```bash
# Check logs for errors
kubectl logs -n mcp-system postgres-mcp-server-xxx

# Common causes:
# - Invalid connection string
# - Network connectivity issues
# - Missing secret
# - PostgreSQL authentication failure

# Verify secret exists
kubectl get secret postgres-mcp-secret -n mcp-system -o yaml

# Test network connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n mcp-system -- ping postgresql-host
```

#### 2. Connection Refused

**Symptoms:**
```
Error: connect ECONNREFUSED postgresql:5432
```

**Solutions:**

```bash
# Verify PostgreSQL service
kubectl get svc -n database

# Check DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -n mcp-system -- nslookup postgresql.database.svc.cluster.local

# Verify network policies allow traffic
kubectl get networkpolicies -n mcp-system
kubectl get networkpolicies -n database
```

#### 3. Authentication Failed

**Symptoms:**
```
Error: password authentication failed for user "mcpuser"
```

**Solutions:**

```bash
# Verify credentials in secret
kubectl get secret postgres-mcp-secret -n mcp-system -o jsonpath='{.data.POSTGRES_CONNECTION_STRING}' | base64 -d

# Test connection from debug pod
kubectl run -it --rm psql-test --image=postgres:15 --restart=Never -n mcp-system -- \
  psql "postgresql://user:pass@host:5432/db" -c "SELECT 1;"
```

#### 4. Resource Constraints

**Symptoms:**
```
OOMKilled or CPU throttling
```

**Solutions:**

```bash
# Check resource usage
kubectl top pods -n mcp-system

# Increase resources
helm upgrade postgres-mcp ./helm-chart \
  --namespace mcp-system \
  --reuse-values \
  --set resources.limits.memory=2Gi \
  --set resources.limits.cpu=2000m
```

### Debug Commands

```bash
# Describe pod for events
kubectl describe pod -n mcp-system -l app.kubernetes.io/name=postgresql-mcp-server

# Get all resources
kubectl get all -n mcp-system

# Check configmaps
kubectl get configmap -n mcp-system

# View full deployment YAML
kubectl get deployment postgres-mcp-server -n mcp-system -o yaml

# Check for pending PVCs
kubectl get pvc -n mcp-system
```

## Production Best Practices

### Security

1. **Use Secrets Management**
   ```bash
   # Never hardcode credentials in values files
   # Use Rancher secrets or external secret managers
   ```

2. **Enable Network Policies**
   ```yaml
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
   ```

3. **Enforce SSL/TLS**
   ```yaml
   postgresql:
     sslMode: require  # or verify-full
   ```

4. **Run as Non-Root**
   ```yaml
   podSecurityContext:
     runAsNonRoot: true
     runAsUser: 1001
     fsGroup: 1001
   ```

### High Availability

1. **Multiple Replicas**
   ```yaml
   replicaCount: 3
   
   podDisruptionBudget:
     enabled: true
     minAvailable: 2
   ```

2. **Pod Anti-Affinity**
   ```yaml
   affinity:
     podAntiAffinity:
       preferredDuringSchedulingIgnoredDuringExecution:
       - weight: 100
         podAffinityTerm:
           topologyKey: kubernetes.io/hostname
   ```

3. **Autoscaling**
   ```yaml
   autoscaling:
     enabled: true
     minReplicas: 3
     maxReplicas: 10
   ```

### Resource Management

1. **Set Resource Requests and Limits**
   ```yaml
   resources:
     requests:
       cpu: 500m
       memory: 512Mi
     limits:
       cpu: 2000m
       memory: 2Gi
   ```

2. **Configure Probes**
   ```yaml
   livenessProbe:
     enabled: true
     initialDelaySeconds: 30
     periodSeconds: 30
   
   readinessProbe:
     enabled: true
     initialDelaySeconds: 10
     periodSeconds: 10
   ```

### Monitoring

1. **Enable Logging**
   ```bash
   # View logs in Rancher UI or via kubectl
   kubectl logs -n mcp-system -l app.kubernetes.io/name=postgresql-mcp-server -f
   ```

2. **Resource Monitoring**
   ```bash
   # Monitor pod resources
   kubectl top pods -n mcp-system
   
   # Watch HPA
   kubectl get hpa -n mcp-system -w
   ```

### Upgrade Strategy

```bash
# Test in staging first
helm upgrade postgres-mcp-staging ./helm-chart \
  --namespace mcp-staging \
  -f values-staging.yaml \
  --dry-run

# Upgrade with rollback capability
helm upgrade postgres-mcp ./helm-chart \
  --namespace mcp-system \
  -f values-production.yaml \
  --wait \
  --timeout 5m

# Rollback if needed
helm rollback postgres-mcp -n mcp-system
```

## Upgrade and Maintenance

### Upgrading the Chart

```bash
# Check current version
helm list -n mcp-system

# Upgrade to new version
helm upgrade postgres-mcp ./helm-chart \
  --namespace mcp-system \
  --reuse-values \
  --set image.tag=1.0.6

# Verify upgrade
kubectl rollout status deployment/postgres-mcp-server -n mcp-system
```

### Backup Configuration

```bash
# Export current values
helm get values postgres-mcp -n mcp-system > backup-values.yaml

# Export all manifests
helm get manifest postgres-mcp -n mcp-system > backup-manifests.yaml
```

### Cleanup

```bash
# Uninstall release
helm uninstall postgres-mcp -n mcp-system

# Remove namespace (if needed)
kubectl delete namespace mcp-system
```

## Support

- **Documentation**: https://github.com/HenkDz/postgresql-mcp-server
- **Issues**: https://github.com/HenkDz/postgresql-mcp-server/issues
- **Helm Chart**: `./helm-chart/`

## License

AGPLv3 - see LICENSE file for details
