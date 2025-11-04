# MongoDB Backup to Google Cloud Storage

Automated MongoDB backups to Google Cloud Storage (GCS) using Docker or Kubernetes.

**Image:** `wltmlx/mongodb-backup-gcs:latest`

## Features

- Automated MongoDB backups using cron jobs
- Google Cloud Storage (GCS) integration
- Docker and Kubernetes/Helm support
- Backup/restore/list operations
- Support for private registries (Artifactory)
- Flexible MongoDB and GCS configuration

## Prerequisites

### GCS Setup

1. Create a GCS bucket:
```bash
gsutil mb gs://my-backup-bucket
```

2. Create a GCS service account:
```bash
gcloud iam service-accounts create mongodb-backup \
  --display-name="MongoDB Backup Service Account"
```

3. Grant necessary permissions:
```bash
PROJECT_ID=$(gcloud config get-value project)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:mongodb-backup@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/storage.objectCreator

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:mongodb-backup@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/storage.objectViewer
```

4. Create and download the service account key:
```bash
gcloud iam service-accounts keys create gcs-key.json \
  --iam-account=mongodb-backup@$PROJECT_ID.iam.gserviceaccount.com
```

## Docker Deployment

### Basic Usage

```bash
docker run -d \
  --env GCS_BUCKET=my-gcs-bucket \
  --env GCS_KEY_FILE_PATH=/secrets/gcs-key.json \
  -v /path/to/gcs-key.json:/secrets/gcs-key.json \
  --env MONGODB_HOST=mongodb.host \
  --env MONGODB_PORT=27017 \
  --env MONGODB_USER=admin \
  --env MONGODB_PASS=password \
  wltmlx/mongodb-backup-gcs:latest
```

### Docker Compose

**For automated backups:**
```yaml
mongodbbackup:
  image: 'wltmlx/mongodb-backup-gcs:latest'
  links:
    - mongodb
  environment:
    - GCS_BUCKET=my-gcs-bucket
    - GCS_KEY_FILE_PATH=/secrets/gcs-key.json
    - BACKUP_FOLDER=prod/db/
  volumes:
    - /path/to/gcs-key.json:/secrets/gcs-key.json
  restart: always
```

**For restore operations:**
```yaml
mongodbbackup:
  image: 'wltmlx/mongodb-backup-gcs:latest'
  links:
    - mongodb
  environment:
    - GCS_BUCKET=my-gcs-bucket
    - GCS_KEY_FILE_PATH=/secrets/gcs-key.json
    - BACKUP_FOLDER=prod/db/
    - INIT_RESTORE=true
    - DISABLE_CRON=true
  volumes:
    - /path/to/gcs-key.json:/secrets/gcs-key.json
```

## Kubernetes / Helm Deployment

For Kubernetes deployments, use the Helm chart. See [helm/README.md](helm/README.md) for detailed Helm instructions.

Quick start:
```bash
helm install mongodb-backup ./helm \
  --set mongodb.host=mongodb \
  --set gcs.bucket=my-backup-bucket \
  --set existingSecret=gcs-credentials
```

## Operations

### Docker: List Backups

```bash
docker exec mongodb-backup-gcs /listbackups.sh
```

### Docker: Restore Latest Backup

```bash
docker exec mongodb-backup-gcs /restore.sh
```

### Docker: Restore Specific Backup

```bash
docker exec mongodb-backup-gcs /restore.sh 20231115T030000
```

### Kubernetes: Configure Automated Backups

Create a `values.yaml` for Helm:

```yaml
mongodb:
  host: "mongodb.default.svc.cluster.local"
  port: 27017
  user: "admin"
  password: "secretpass"
  db: ""

gcs:
  bucket: "my-backup-bucket"

backupFolder: "mongodb-backups/"
cronTime: "0 3 * * *"  # Daily at 3 AM UTC
timezone: "UTC"

existingSecret: "gcs-credentials"
```

Install with Helm:
```bash
helm install mongodb-backup ./helm -f values.yaml
```

### Kubernetes: One-Time Restore from Latest Backup

Create a `values-restore.yaml`:

```yaml
mongodb:
  host: "mongodb.default.svc.cluster.local"
  port: 27017
  user: "admin"
  password: "secretpass"

gcs:
  bucket: "my-backup-bucket"

initRestore: true      # Restore latest backup on startup
disableCron: true      # Don't run scheduled backups after restore

existingSecret: "gcs-credentials"
```

Deploy with:
```bash
helm install mongodb-restore ./helm -f values-restore.yaml
```

### Kubernetes: Manual Operations in Running Pod

For manual operations in an already-running pod:

List backups:
```bash
kubectl exec -it deployment/mongodb-backup -- /listbackups.sh
```

Restore specific backup:
```bash
kubectl exec -it deployment/mongodb-backup -- /restore.sh 20231115T030000
```

## Configuration

### GCS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GCS_BUCKET` | - | GCS bucket name (required) |
| `GCS_KEY_FILE_PATH` | `/secrets/gcs-key.json` | Path to GCS service account key file |
| `BACKUP_FOLDER` | root | Folder path in GCS bucket (e.g., `mongodb-backups/`) |

### MongoDB Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGODB_HOST` | - | MongoDB hostname or IP |
| `MONGODB_PORT` | 27017 | MongoDB port |
| `MONGODB_USER` | - | MongoDB username (auto-set to 'admin' if password is set) |
| `MONGODB_PASS` | - | MongoDB password |
| `MONGODB_DB` | - | Specific database to backup (empty = all databases) |
| `EXTRA_OPTS` | - | Extra options for mongodump/mongorestore |

### Scheduling Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CRON_TIME` | `0 3 * * *` | Cron schedule (daily at 3 AM UTC) |
| `TZ` | `UTC` | Timezone |
| `CRON_TZ` | `UTC` | Cron job timezone |

### Behavior Flags

| Variable | Default | Description |
|----------|---------|-------------|
| `INIT_BACKUP` | - | Create backup on startup |
| `INIT_RESTORE` | - | Restore latest backup on startup |
| `DISABLE_CRON` | - | Disable scheduled backups (use for one-time restore) |

## Troubleshooting

### GCS Authentication Error
- Ensure service account key is properly mounted
- Verify service account has Storage Object Creator and Storage Object Viewer roles
- Check `GCS_KEY_FILE_PATH` matches the mounted volume path

### MongoDB Connection Error
- Verify MongoDB hostname and port
- Check MongoDB credentials
- Ensure MongoDB is accessible from the container

### Missing or Failed Backups
- Check container/pod logs: `docker logs` or `kubectl logs`
- Verify cron is enabled: `DISABLE_CRON` should not be set
- Check GCS bucket has available quota
- Verify disk space on MongoDB host

## License

Apache License 2.0

## Acknowledgements

Forked from [halvves](https://github.com/halvves)'s fork of [tutumcloud/mongodb-backup](https://github.com/tutumcloud/mongodb-backup)
