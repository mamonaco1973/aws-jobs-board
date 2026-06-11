# CLAUDE.md

This file provides guidance to Claude Code when working with code in this
repository.

## What This App Does

AWS Job Board — Ruby on Rails 7.1 application running on ECS Fargate. Two
roles: Candidates browse and apply to jobs (with PDF resume upload via
ActiveStorage → S3); Employers create company profiles, post jobs, and review
applications with status management. Devise handles authentication (bcrypt
sessions). Pundit policy objects enforce per-resource authorization. Sidekiq
processes background notification jobs from an ElastiCache Redis queue. All
infrastructure is Terraform-managed; credentials are injected at ECS task
startup from Secrets Manager — never baked into the image.

## Deployment Commands

All deployment runs from the repo root:

```bash
./apply.sh      # Full deploy: 01-network → docker build → 03-ecs → validate
./destroy.sh    # Reverse teardown: 03-ecs → ECR → Secrets → 01-network
./check_env.sh  # Validate required tools: aws, terraform, docker, jq
./validate.sh   # Poll ALB until HTTP 200; Fargate needs ~5-10 min to start
```

There are no test or lint commands configured.

## Architecture

```
01-network/          # Terraform: VPC, RDS PostgreSQL 16, ElastiCache Redis 7,
                     #   ECR, S3 (uploads), Secrets Manager (3 secrets)
03-ecs/              # Terraform: ECS Fargate cluster, ALB, task def, IAM roles
02-docker/jobboard/  # Rails 7.1 app + Dockerfile + startup.sh
```

### Deployment Flow

`apply.sh` runs in order:

1. `01-network/` — provisions all persistent infrastructure; exports
   `S3_BUCKET` and `ECR_URL` from Terraform outputs
2. Docker build + ECR push — single-stage `ruby:3.3-slim` image
3. `03-ecs/` — deploys Fargate service; `s3_bucket_name` passed as a
   Terraform variable (not a data source — bucket name has random suffix)
4. `validate.sh` — polls `/users/sign_in` for HTTP 200

### Container Startup (`startup.sh`)

On each task start:
- Waits for RDS to accept connections (30 retries × 5s)
- Runs `rails db:prepare` (creates DB schema + runs migrations idempotently)
- Seeds demo data if `Job.count.zero?`
- Starts Sidekiq in background
- Exec's Puma in foreground

### Rails Application Layout

```
app/models/
  user.rb             # Devise + role enum (candidate=0, employer=1)
  company.rb          # belongs_to :user (employer only)
  job.rb              # belongs_to :company, keyword/location scopes
  job_application.rb  # belongs_to user+job, has_one_attached :resume,
                      #   unique [user_id, job_id], after_create → Sidekiq

app/policies/         # Pundit — one policy per model
  job_policy.rb
  job_application_policy.rb
  company_policy.rb

app/controllers/
  jobs_controller.rb
  applications_controller.rb
  companies_controller.rb
  dashboard_controller.rb
  employer/           # Namespaced — employer views own jobs + applications
    jobs_controller.rb
    applications_controller.rb

app/jobs/
  application_notification_job.rb  # Sidekiq, queue :default

app/mailers/
  employer_mailer.rb  # new_application email to employer

db/migrate/           # 6 migrations; timestamps frozen at 20240101*
db/seeds.rb           # 2 employers, 2 companies, 6 jobs, 2 candidates
                      # all idempotent via find_or_create_by!
                      # password: "password123"
```

### Secrets Injection

Three Secrets Manager secrets are created in `01-network/secrets.tf`:
- `jobboard_database_url` — full `postgresql://` connection string
- `jobboard_redis_url` — `redis://<endpoint>:6379/0`
- `jobboard_secret_key_base` — 128-char random key

All three are injected into the ECS task via the `secrets:` block in the task
definition (`03-ecs/ecs.tf`). Rails reads them as `DATABASE_URL`,
`REDIS_URL`, and `SECRET_KEY_BASE` env vars.

### Cross-Phase Data Flow

| Value | Source | Consumer |
|---|---|---|
| `ECR_URL` | `01-network` terraform output | Docker build tag + push |
| `S3_BUCKET` | `01-network` terraform output | `03-ecs` `-var` argument |
| VPC/subnet IDs | tag-based data sources | `03-ecs/data.tf` |
| Secret ARNs | name-based data sources | `03-ecs/data.tf` → task def |

### Key Terraform Files

- `01-network/rds.tf` — RDS PostgreSQL 16, `db.t3.micro`, private subnets,
  `skip_final_snapshot = true`
- `01-network/elasticache.tf` — Redis 7, `cache.t3.micro`, single node
- `01-network/secrets.tf` — `random_password` for DB and SECRET_KEY_BASE;
  plain-string secrets (not JSON) for direct ECS injection
- `03-ecs/roles.tf` — execution role (ECR + CW + read 3 secrets); runtime
  role (S3 uploads bucket + SSM ECS Exec)
- `03-ecs/ecs.tf` — task def with `secrets:` block; `enable_execute_command`
  for `aws ecs execute-command` access

## Code Commenting Standards

Follow the workspace-level standards in `c:\cloudenv\.claude\CLAUDE.md`.
Key rules for this project:

- Comment lines ≤ 80 characters
- Shell scripts: `set -euo pipefail` at top, section banners for major blocks
- Terraform: section headers for logical resource groups; explain *why*
  infrastructure exists, not what the resource type says
- Ruby: Google-style docstrings on non-trivial methods; inline comments
  explain intent only
- No comments that restate the code
