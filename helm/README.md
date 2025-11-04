# MongoDB Backup to GCS - Helm Chart

Kubernetes Helm chart for deploying MongoDB backups to Google Cloud Storage (GCS).

For general setup information, prerequisites, and GCS service account creation, see the [main README.md](../README.md#prerequisites).

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- GCS bucket and service account key (see [main README](../README.md#prerequisites))

## Quick Start

Create image pull secret for GCS credentials:
```bash
kubectl create secret generic gcs-credentials \
  --from-file=gcs-key.json=/path/to/gcs-key.json
```

Install with Helm:
```bash
helm install mongodb-backup ./helm \
  --set mongodb.host=mongodb \
  --set gcs.bucket=my-backup-bucket \
  --set existingSecret=gcs-credentials
```

## Installation Examples

### Basic Backup Setup

```bash
helm install mongodb-backup ./helm \
  --set mongodb.host=mongodb.default.svc.cluster.local \
  --set mongodb.user=admin \
  --set mongodb.password=secretpass \
  --set gcs.bucket=my-backup-bucket \
  --set gcsKeyContent=$(cat gcs-key.json | base64)
```

### Restore from Latest Backup

```bash
helm install mongodb-restore ./helm \
  --set initRestore=true \
  --set disableCron=true \
  --set mongodb.host=mongodb.default.svc.cluster.local \
  --set mongodb.user=admin \
  --set mongodb.password=secretpass \
  --set gcs.bucket=my-backup-bucket \
  --set gcsKeyContent=$(cat gcs-key.json | base64)
```

### Using Existing Secret

```bash
helm install mongodb-backup ./helm \
  --set existingSecret=gcs-credentials \
  --set existingSecretKey=gcs-key.json \
  --set mongodb.host=mongodb.default.svc.cluster.local \
  --set gcs.bucket=my-backup-bucket
```

### Using Artifactory Registry

Create image pull secret for Artifactory:
```bash
kubectl create secret docker-registry artifactory-credentials \
  --docker-server=artifactory.example.com \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email>
```

Install with Artifactory configuration:
```bash
helm install mongodb-backup ./helm \
  --set registry=artifactory.example.com \
  --set image.repository=docker/mongodb-backup-gcs \
  --set image.tag=latest \
  --set imagePullSecrets[0].name=artifactory-credentials \
  --set mongodb.host=mongodb \
  --set gcs.bucket=my-backup-bucket \
  --set existingSecret=gcs-credentials
```

### Production Setup

For production environments with resource limits and Artifactory:

```bash
helm install mongodb-backup ./helm \
  --set registry=artifactory.example.com \
  --set image.repository=docker/mongodb-backup-gcs \
  --set imagePullSecrets[0].name=artifactory-credentials \
  --set mongodb.host=mongodb.production.svc.cluster.local \
  --set mongodb.user=backup \
  --set mongodb.password=secretpass \
  --set mongodb.db="" \
  --set gcs.bucket=prod-mongodb-backups \
  --set BACKUP_FOLDER=production/ \
  --set cronTime="0 */6 * * *" \
  --set resources.requests.cpu=250m \
  --set resources.requests.memory=256Mi \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  --set existingSecret=gcs-credentials
```

## Configuration

### GCS Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `registry` | docker.io | Docker registry URL |
| `image.repository` | wltmlx/mongodb-backup-gcs | Image repository |
| `image.tag` | latest | Image tag |
| `image.pullPolicy` | IfNotPresent | Pull policy |
| `imagePullSecrets` | [] | Secrets for private registries |

### MongoDB Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mongodb.host` | mongodb | MongoDB hostname |
| `mongodb.port` | 27017 | MongoDB port |
| `mongodb.user` | "" | MongoDB username |
| `mongodb.password` | "" | MongoDB password |
| `mongodb.db` | "" | Specific database (empty = all) |

### Backup Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `gcs.bucket` | "" | GCS bucket name (required) |
| `gcs.keyFilePath` | /secrets/gcs-key.json | Path to GCS key |
| `backupFolder` | mongodb-backups/ | Folder path in bucket |
| `cronTime` | 0 3 * * * | Cron schedule |
| `timezone` | UTC | Timezone |

### Behavior Flags

| Parameter | Default | Description |
|-----------|---------|-------------|
| `initBackup` | false | Create backup on startup |
| `initRestore` | false | Restore latest on startup |
| `disableCron` | false | Disable scheduled backups |
| `extraOpts` | "" | Extra mongodump/mongorestore options |

### Resource Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `replicaCount` | 1 | Number of replicas |
| `resources.requests.cpu` | 100m | CPU request |
| `resources.requests.memory` | 128Mi | Memory request |
| `resources.limits.cpu` | 500m | CPU limit |
| `resources.limits.memory` | 512Mi | Memory limit |

## Operations

### List Backups
```bash
kubectl exec -it deployment/mongodb-backup -- /listbackups.sh
```

### Restore Latest Backup
```bash
kubectl exec -it deployment/mongodb-backup -- /restore.sh
```

### Restore Specific Backup
```bash
kubectl exec -it deployment/mongodb-backup -- /restore.sh 20231115T030000
```

### View Logs
```bash
kubectl logs -f deployment/mongodb-backup
```

## Troubleshooting

### GCS Authentication Error
- Verify service account key is properly encoded in base64
- Check service account has Storage Object Creator and Storage Object Viewer roles
- Ensure `GCS_KEY_FILE_PATH` matches mounted path in values

### MongoDB Connection Error
- Verify MongoDB hostname is correct and accessible
- Check MongoDB credentials
- Confirm MongoDB is running and accepting connections

### Missing Backups
- Check pod is running: `kubectl get pods -l app.kubernetes.io/name=mongodb-backup-gcs`
- Verify cron is enabled: `DISABLE_CRON` should not be set
- Check logs: `kubectl logs <pod-name>`

## Upgrading

```bash
helm upgrade mongodb-backup ./helm -f values.yaml
```

## Uninstalling

```bash
helm uninstall mongodb-backup
```

## License

Apache License 2.0
