# Seed data for demo — creates employers, companies, jobs, and candidates.
# Idempotent: wraps each creation in find_or_create patterns.

puts "Seeding demo data..."

# ------------------------------------------------------------------------------
# Employers
# ------------------------------------------------------------------------------
employer1 = User.find_or_create_by!(email: "employer1@example.com") do |u|
  u.password = "password123"
  u.role     = :employer
end

employer2 = User.find_or_create_by!(email: "employer2@example.com") do |u|
  u.password = "password123"
  u.role     = :employer
end

# ------------------------------------------------------------------------------
# Companies
# ------------------------------------------------------------------------------
company1 = Company.find_or_create_by!(user: employer1) do |c|
  c.name        = "Acme Corp"
  c.location    = "New York, NY"
  c.website     = "https://acme.example.com"
  c.description = "A fast-moving tech company building the future of automation."
end

company2 = Company.find_or_create_by!(user: employer2) do |c|
  c.name        = "Globex Industries"
  c.location    = "Austin, TX"
  c.website     = "https://globex.example.com"
  c.description = "Enterprise software solutions for the modern enterprise."
end

# ------------------------------------------------------------------------------
# Jobs
# ------------------------------------------------------------------------------
jobs_data = [
  { company: company1, title: "Senior Rails Developer",       location: "Remote",        salary_min: 120_000, salary_max: 160_000, job_type: "Full-time",
    description: "We're looking for an experienced Rails developer to lead our backend team. You'll architect new features, mentor junior developers, and drive technical decisions.\n\nRequirements:\n- 5+ years Ruby on Rails experience\n- Strong PostgreSQL skills\n- Experience with AWS (ECS, RDS, S3)\n- Familiarity with Sidekiq and Redis\n- TDD mindset" },
  { company: company1, title: "Frontend Engineer (React)",    location: "New York, NY",   salary_min: 100_000, salary_max: 140_000, job_type: "Full-time",
    description: "Build responsive, accessible UIs using React and TypeScript.\n\nRequirements:\n- 3+ years React experience\n- TypeScript proficiency\n- REST/GraphQL API integration\n- CSS-in-JS or Tailwind experience" },
  { company: company1, title: "DevOps Engineer",              location: "Remote",         salary_min: 110_000, salary_max: 150_000, job_type: "Full-time",
    description: "Own our AWS infrastructure and CI/CD pipelines. Terraform, ECS, RDS, and CloudWatch are your daily toolkit." },
  { company: company2, title: "Ruby on Rails Engineer",       location: "Austin, TX",     salary_min: 90_000,  salary_max: 130_000, job_type: "Full-time",
    description: "Join our product team to build and maintain our core Rails application serving 50k+ users." },
  { company: company2, title: "Data Engineer",                location: "Remote",         salary_min: 115_000, salary_max: 155_000, job_type: "Full-time",
    description: "Design and maintain data pipelines. Redshift, dbt, and Airflow experience preferred." },
  { company: company2, title: "QA Engineer (Contract)",       location: "Austin, TX",     salary_min: 70_000,  salary_max: 90_000,  job_type: "Contract",
    description: "Write and maintain automated test suites using RSpec and Cypress. Collaborate with product and engineering to ensure quality." },
]

jobs_data.each do |attrs|
  company = attrs.delete(:company)
  company.jobs.find_or_create_by!(title: attrs[:title]) do |j|
    j.assign_attributes(attrs)
  end
end

# ------------------------------------------------------------------------------
# Candidates
# ------------------------------------------------------------------------------
User.find_or_create_by!(email: "candidate1@example.com") do |u|
  u.password = "password123"
  u.role     = :candidate
end

User.find_or_create_by!(email: "candidate2@example.com") do |u|
  u.password = "password123"
  u.role     = :candidate
end

puts "Done. Seeded #{Company.count} companies, #{Job.count} jobs, #{User.count} users."
