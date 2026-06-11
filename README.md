# AWS Job Board — Ruby on Rails on ECS Fargate

This project delivers a fully functional **job board web application** on AWS,
built with **Ruby on Rails 7.1**, deployed as a **Docker container on Amazon
ECS Fargate**, and backed by **Amazon RDS (PostgreSQL)**, **Amazon ElastiCache
(Redis)**, and **Amazon S3**.

It uses **Terraform** to provision all infrastructure and a single `apply.sh`
script to build and deploy the entire stack end-to-end — from VPC and database
to container image and running ECS service.

The application supports two user roles: **Candidates** browse and apply for
jobs, uploading PDF resumes via ActiveStorage to S3. **Employers** create
company profiles, post jobs, and review incoming applications with status
management. Background notifications are sent via **Sidekiq** workers backed
by Redis.

Authentication is handled by **Devise** (bcrypt sessions) and authorization by
**Pundit** policy objects — no external identity provider required.

## Key Capabilities Demonstrated

1. **Ruby on Rails MVC Application** — Full Rails 7.1 stack with ActiveRecord,
   Devise authentication, Pundit authorization, ActiveStorage file uploads,
   Sidekiq background jobs, and ActionMailer notifications.
2. **Role-Based Authorization** — Two distinct roles (Candidate, Employer) with
   Pundit policy objects enforcing per-resource access control throughout the
   application.
3. **File Uploads to S3** — Candidates attach PDF/Word resumes via
   ActiveStorage. The ECS task IAM role grants S3 access — no long-lived
   credentials in the application.
4. **Background Job Processing** — Sidekiq processes application notification
   jobs from a Redis queue. Sidekiq runs in the same container as Puma for
   demo simplicity; a natural interview talking point for production separation.
5. **ECS Fargate Container Deployment** — The Rails app runs serverlessly on
   Fargate with no EC2 instances to manage. The ECS task pulls secrets from
   Secrets Manager at startup — credentials never touch the image.
6. **RDS PostgreSQL + ElastiCache Redis** — A managed PostgreSQL database
   stores all application data. Redis backs the Sidekiq queue and Action Cable.
7. **Terraform Infrastructure as Code** — All AWS resources (VPC, RDS,
   ElastiCache, ECR, S3, Secrets Manager, ALB, ECS) are provisioned in two
   Terraform phases with explicit dependency ordering.
8. **Database Migrations on Deploy** — `rails db:prepare` runs in the container
   entrypoint on startup, applying all ActiveRecord migrations before Puma
   accepts traffic.
9. **Seed Data** — The database is seeded with demo employers, companies, jobs,
   and candidates on first deploy, providing a fully populated application
   immediately.

## Architecture

```
Internet
    │
    ▼
Application Load Balancer (public subnets, port 80)
    │
    ▼
ECS Fargate Task (private subnets, port 3000)
  ├── Puma (Rails web server)
  └── Sidekiq (background worker, Redis queue)
    │                   │
    ▼                   ▼
RDS PostgreSQL     ElastiCache Redis
(private subnet)   (private subnet)
    │
    ▼
S3 (ActiveStorage resume uploads)
Secrets Manager (DATABASE_URL, REDIS_URL, SECRET_KEY_BASE)
ECR (container image)
```

## Prerequisites

* [An AWS Account](https://aws.amazon.com/console/)
* [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Install Terraform](https://developer.hashicorp.com/terraform/install)
* [Install Docker](https://docs.docker.com/engine/install/)
* [Install jq](https://jqlang.github.io/jq/download/)

Region is hardcoded to `us-east-1`.

If this is your first time using AWS with Terraform, we recommend starting with
this video:
**[AWS + Terraform: Easy Setup](https://www.youtube.com/watch?v=9clW3VQLyxA)**

## Download this Repository

```bash
git clone https://github.com/mamonaco1973/aws-jobs-board.git
cd aws-jobs-board
```

## Build the Code

Run [check_env](check_env.sh) to validate your environment, then run
[apply](apply.sh) to provision all infrastructure and deploy the application.

```bash
~/aws-jobs-board$ ./apply.sh
NOTE: Running environment validation...
NOTE: Validating that required commands are found in your PATH.
NOTE: aws is found in the current PATH.
NOTE: terraform is found in the current PATH.
NOTE: docker is found in the current PATH.
NOTE: jq is found in the current PATH.
NOTE: Successfully logged into AWS.
NOTE: Building network infrastructure...
...
NOTE: Building and pushing Docker image to ECR...
...
NOTE: Deploying ECS Fargate cluster and service...
...
NOTE: Waiting for http://<alb-dns>/users/sign_in to return HTTP 200...
NOTE: JobBoard is healthy (HTTP 200).
NOTE: Deployment complete.
NOTE: JobBoard URL:           http://<alb-dns>
NOTE: Candidate login:        candidate1@example.com / password123
NOTE: Employer login:         employer1@example.com  / password123
```

`apply.sh` runs four phases in order:

1. **Phase 1 — Network Infrastructure** (`01-network/`): Provisions VPC,
   subnets, Internet Gateway, NAT Gateway, RDS PostgreSQL 16, ElastiCache
   Redis 7, ECR repository, S3 bucket for uploads, and Secrets Manager entries
   for all credentials.
2. **Phase 2 — Docker Build** (`02-docker/jobboard/`): Builds the Rails
   container image and pushes it to ECR.
3. **Phase 3 — ECS Fargate** (`03-ecs/`): Deploys the ECS cluster, ALB,
   target group, task definition, and ECS service. Secrets Manager ARNs are
   wired into the task definition so credentials are injected at task startup.
4. **Phase 4 — Validation**: Polls the ALB health endpoint until Rails responds
   HTTP 200. Fargate tasks need ~5–10 minutes to start, run migrations, and
   join the target group.

### Build Results

When deployment completes, the following resources exist in `us-east-1`:

- **Networking:**
  - VPC `10.0.0.0/23` with 2 private and 2 public subnets across 2 AZs
  - Internet Gateway, NAT Gateway, route tables for private subnet egress

- **Database Layer:**
  - RDS PostgreSQL 16 (`db.t3.micro`, 20 GB) in private subnets
  - ElastiCache Redis 7 (`cache.t3.micro`, single node) in private subnets
  - Passwords randomly generated by Terraform; stored in Secrets Manager
  - Full Rails schema created by `rails db:prepare` on first container start

- **Storage:**
  - S3 bucket (`jobboard-uploads-<random>`) for ActiveStorage resume files
  - Public access blocked; IAM role grants ECS task read/write access

- **Container Infrastructure:**
  - ECR repository `jobboard` holding the Rails application image
  - ECS Fargate cluster with Container Insights enabled
  - CloudWatch log group `/ecs/jobboard` (7-day retention)

- **Application Load Balancer:**
  - ALB in public subnets, port 80 forwarding to ECS tasks on port 3000
  - Health check against `/users/sign_in`

- **Security & IAM:**
  - ALB security group (port 80 inbound from internet)
  - ECS task security group (port 3000 from ALB only; RDS/Redis from VPC CIDR)
  - ECS task execution role: pull from ECR, write CloudWatch, read 3 secrets
  - ECS task runtime role: S3 read/write on uploads bucket, SSM for ECS Exec

- **Secrets Manager:**
  - `jobboard_database_url` — full `postgresql://` connection string
  - `jobboard_redis_url` — `redis://` endpoint with database index
  - `jobboard_secret_key_base` — 128-character random key for Rails sessions

## Demo Users

Seed data is loaded automatically on first deploy. All accounts use password
`password123`.

| Email | Role | Notes |
|---|---|---|
| `employer1@example.com` | Employer | Owns Acme Corp, 3 jobs posted |
| `employer2@example.com` | Employer | Owns Globex Industries, 3 jobs posted |
| `candidate1@example.com` | Candidate | Can apply to any job |
| `candidate2@example.com` | Candidate | Can apply to any job |

You can also register new accounts at `/users/sign_up` and choose a role at
registration time.

## Using the Application

### As a Candidate

1. Sign in as `candidate1@example.com` (or register a new Candidate account).
2. Browse the job listings at the home page. Use the keyword and location
   search fields to filter.
3. Click a job title to view the full description and salary range.
4. Click **Apply** to open the application form. Write a cover letter and
   attach your resume (PDF or Word, any size).
5. Submit — the employer receives an email notification via Sidekiq.
6. You cannot apply to the same job twice; the Apply button is replaced with
   an "Already Applied" notice on subsequent visits.

### As an Employer

1. Sign in as `employer1@example.com` (or register a new Employer account).
2. On first login you are prompted to create a company profile if one does not
   exist. Fill in the company name, location, website, and description.
3. Post new jobs from the job listing page using **Post a Job**.
4. Navigate to **Employer Dashboard** to see all your posted jobs and the
   number of applications received.
5. Click a job in the dashboard to see each application, the candidate's cover
   letter, and a link to download their uploaded resume.
6. Update an application's status (Pending → Reviewed → Accepted / Rejected)
   from the application detail page.

## Application Structure

```
01-network/                  # Terraform: VPC, RDS, Redis, ECR, S3, Secrets
03-ecs/                      # Terraform: ECS Fargate, ALB, IAM roles
02-docker/jobboard/          # Rails 7.1 application
  app/
    models/                  # User, Company, Job, JobApplication
    policies/                # Pundit: JobPolicy, JobApplicationPolicy, CompanyPolicy
    controllers/
      employer/              # Namespaced employer controllers
    views/                   # ERB templates with Tailwind CSS (CDN)
    jobs/                    # ApplicationNotificationJob (Sidekiq)
    mailers/                 # EmployerMailer
  db/
    migrate/                 # 6 migrations: users, companies, jobs, applications, AS
    seeds.rb                 # Demo employers, companies, jobs, candidates
  config/
    routes.rb
    storage.yml              # ActiveStorage → S3 via IAM role
  Dockerfile
  startup.sh                 # Waits for DB, runs db:prepare, starts Sidekiq + Puma
apply.sh
destroy.sh
check_env.sh
validate.sh
```

## Destroy

```bash
./destroy.sh
```

Tears down all resources in reverse dependency order:

1. ECS Fargate service and ALB (`03-ecs/`)
2. ECR repository (force-deletes all images)
3. Secrets Manager entries (force-delete bypasses recovery window so
   re-deploys can reuse the same secret names)
4. Network infrastructure — VPC, RDS, ElastiCache, S3 (`01-network/`)
