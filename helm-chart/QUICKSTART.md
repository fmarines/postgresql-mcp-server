# PostgreSQL MCP Server Helm Chart - Quick Start

Get the PostgreSQL MCP Server running on Rancher in 5 minutes!

## 🚀 Quick Deploy

### 1. Create Database Secret

```bash
kubectl create secret generic postgres-mcp-secret \
  --namespace=default \
  --from-literal=POSTGRES_CONNECTION_STRING="postgresql://user:password@host:5432/database"
```

### 2. Install Chart

```bash
cd helm-chart
helm install postgres-mcp . \
  --set postgresql.existingSecret=postgres-mcp-secret
```

### 3. Verify

```bash
kubectl get pods -l app.kubernetes.io/name=postgresql-mcp-server
kubectl logs -l app.kubernetes.io/name=postgresql-mcp-server --tail=50
```

## 📋 What's Included

```
helm-chart/
├── Chart.yaml                    # Chart metadata
├── values.yaml                   # Default configuration
├── templates/                    # Kubernetes manifests
│   ├── deployment.yaml          # Main deployment
│   ├── service.yaml             # Service (optional)
│   ├── configmap.yaml           # Configuration
│   ├── secret.yaml              # Secrets management
│   ├── serviceaccount.yaml      # Service account
│   ├── hpa.yaml                 # Auto-scaling
│   ├── pdb.yaml                 # Pod disruption budget
│   ├── networkpolicy.yaml       # Network policies
│   ├── _helpers.tpl             # Template helpers
│   └── NOTES.txt                # Post-install notes
├── examples/                     # Example configurations
│   ├── values-development.yaml
│   ├── values-production.yaml
│   └── values-rancher.yaml
├── README.md                     # Full documentation
└── QUICKSTART.md                # This file
```

## 🎯 Common Scenarios

### Development Environment

```bash
helm install postgres-mcp ./helm-chart \
  -f examples/values-development.yaml \
  --set postgresql.password=dev_password
```

### With Existing PostgreSQL (Same Namespace)

```bash
# Install PostgreSQL first (bitnami chart)
helm install postgresql bitnami/postgresql \
  --namespace mcp-system \
  --create-namespace

# Deploy MCP Server using the PostgreSQL secret (SAME namespace!)
helm install postgres-mcp ./helm-chart \
  --namespace mcp-system \
  -f examples/values-external-postgresql.yaml
```

### Production with HA

```bash
# Create secret first
kubectl create secret generic postgres-prod-secret \
  --from-literal=POSTGRES_CONNECTION_STRING="postgresql://user:pass@host:5432/db?sslmode=require"

# Deploy with HA configuration
helm install postgres-mcp ./helm-chart \
  -f examples/values-production.yaml \
  --namespace production \
  --create-namespace
```

### Rancher-Specific

```bash
helm install postgres-mcp ./helm-chart \
  -f examples/values-rancher.yaml \
  --namespace mcp-system \
  --create-namespace
```

## 🔧 Essential Configuration

### Database Connection Options

**Option 1: Existing Secret (Recommended)**
```yaml
postgresql:
  existingSecret: my-secret-name
```

**Option 2: Direct Configuration**
```yaml
postgresql:
  host: postgresql.database.svc.cluster.local
  port: 5432
  database: mydb
  username: myuser
  password: mypassword
  sslMode: require
```

### Resource Sizing

**Small (Development)**
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

**Large (Production)**
```yaml
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### High Availability

```yaml
replicaCount: 3

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10

podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

## 📊 Verify Deployment

```bash
# Check deployment status
helm status postgres-mcp

# View pods
kubectl get pods -l app.kubernetes.io/name=postgresql-mcp-server

# Follow logs
kubectl logs -f -l app.kubernetes.io/name=postgresql-mcp-server

# Check resource usage
kubectl top pods -l app.kubernetes.io/name=postgresql-mcp-server
```

## 🔄 Upgrade

```bash
# Upgrade with new values
helm upgrade postgres-mcp ./helm-chart \
  --reuse-values \
  --set image.tag=1.0.6

# Or with new values file
helm upgrade postgres-mcp ./helm-chart \
  -f my-new-values.yaml
```

## 🗑️ Uninstall

```bash
helm uninstall postgres-mcp
```

## 📚 Learn More

- **Full Documentation**: [README.md](README.md)
- **Rancher Guide**: [../RANCHER_DEPLOYMENT_GUIDE.md](../RANCHER_DEPLOYMENT_GUIDE.md)
- **Project README**: [../README.md](../README.md)

## ⚠️ Troubleshooting

### Pod not starting?
```bash
kubectl describe pod -l app.kubernetes.io/name=postgresql-mcp-server
kubectl logs -l app.kubernetes.io/name=postgresql-mcp-server --previous
```

### Connection issues?
```bash
# Test from a debug pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql "postgresql://user:pass@host:5432/db" -c "SELECT 1;"
```

### Need help?
- Check logs: `kubectl logs -l app.kubernetes.io/name=postgresql-mcp-server`
- Review events: `kubectl get events --sort-by='.lastTimestamp'`
- See full guide: [README.md](README.md)

## 📝 Notes

- **YAML Lint Warnings**: The IDE may show YAML lint errors in template files. These are expected and can be ignored - they contain Go template syntax that YAML linters don't understand. The charts work correctly with Helm.

- **Secrets**: Always use Kubernetes secrets for sensitive data in production. Never commit passwords to values files.

- **SSL/TLS**: Enable SSL for production PostgreSQL connections using `sslMode: require`.

Happy deploying! 🎉
