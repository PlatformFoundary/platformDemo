# How my Platform Should Look like

## Atlantis, Terragrunt (IAC)

- IAC in GitOps way where plan and apply happens at PR level
- No repetition of code and follow DRY principles strictly
- This is for initial Platform Setup
- Terragrunt manages shared configuration (provider, backend, remote state) centrally; individual environments/modules only declare overrides
- Atlantis runs `plan` automatically on PR open/update and posts the output as a PR comment for review
- `apply` is gated behind required approvals (e.g. Platform Engineering sign-off) and only runs after merge or an explicit `atlantis apply` comment
- State locking enabled to prevent concurrent applies stepping on each other
- Policy-as-code checks (e.g. OPA/Conftest, Sentinel) run as part of the plan stage to block non-compliant infra before it reaches apply
- Drift detection job runs periodically to flag manual changes made outside of Git

## Developer Experience

- A portal where developers update their infrastructure in JSON format, not in HCL, since that's what they're already familiar with
- JSON input is validated against a schema and translated into the underlying Terraform/Terragrunt modules, so developers never touch HCL directly
- It should create the required basic infra post merging of the PR after approval from the Platform Engineering team
- Examples: AKS clusters, Kafka, managed databases, storage accounts, etc.
- A curated catalog of approved resource "types" with sane defaults (sizing, networking, tags) so developers can't request something outside platform standards
- Built-in cost estimate shown on the PR before approval, so requesters see the impact of what they're asking for

## Backstage

- A one stop shop for developers to view, management to analyze FinOps, and a bird's eye view of the infrastructure
- Visualize cost, deployments, application versioning, certificate expiry, etc.
- Software catalog of all services/apps with clear ownership (team, on-call, repo link)
- Golden path templates (Backstage Software Templates) to scaffold new services consistently
- TechDocs for centralized, versioned documentation living next to the code
- Scorecards to track each service's compliance with platform standards (security, observability, CI/CD adoption)

## Org Level Observability Platform

- Takes away the burden on developers to worry about infra, logs, etc.
- Just consume the package in your code and follow the standards of platform coding
- Standard logging/metrics/tracing SDK that auto-instruments common frameworks, so teams get observability "for free" by following naming/tagging conventions
- Centralized dashboards and alerting templates (e.g. Prometheus/Grafana) pre-built per service type, instead of every team reinventing them
- SLO/SLA tracking baked in, so platform and product teams share a common definition of "healthy"
- Standardized log retention, sampling, and cost controls managed centrally rather than per-team

## One Touch Initiative

- A platform where a new team can request application onboarding
- In the backend, a GitHub Action or similar workflow runs and creates the boilerplate GitHub repo with standards as per the org structure
- Further, since the GitHub repo contains boilerplate code: build it, run unit tests, push the image to ACR, deploy it to the application, and visualize logs and metrics in the observability platform
- Repo comes pre-wired with Dockerfile, Helm chart/Kustomize manifests, and a standard CI/CD pipeline template
- Security scanning baked into the pipeline by default: SAST, dependency/image vulnerability scanning before push to ACR
- Environment promotion flow (dev -> staging -> prod) follows the same GitOps PR-based approval model as the IAC layer
- Secrets are injected via Key Vault integration out of the box, no hardcoded credentials in the boilerplate
- New service is auto-registered in the Backstage catalog as part of the onboarding workflow, so it's discoverable from day one

## Testing Standards

- A standard, non-negotiable test pyramid baked into every boilerplate repo from the One Touch Initiative, not left for each team to decide on its own
- **Unit testing**: mandatory minimum coverage threshold enforced in CI; pipeline fails the build if coverage drops below the org standard
- **Integration testing**: spins up dependent services (DB, cache, message broker) via test containers as part of the pipeline, validating the service against real interfaces rather than mocks alone
- **Contract testing (Pact)**: consumer-driven contracts published to a shared Pact Broker; provider verification runs in CI before a service can deploy, catching breaking API changes between teams before they hit an environment
- **End-to-end testing**: a thin layer of critical user-journey tests run post-deployment in staging, kept deliberately small to avoid flaky, slow pipelines
- **Performance/load testing**: standard load test templates (e.g. k6/Locust) triggered for services above a defined criticality tier, with pass/fail thresholds tied to SLOs
- **Security testing**: SAST/DAST and dependency scanning treated as test gates, not optional checks, consistent with the Security & Governance standards above
- Test results and coverage trends surfaced in Backstage scorecards, so testing maturity is visible org-wide, not just buried in CI logs
- Environment promotion (dev -> staging -> prod) gated on these test stages passing, in line with the same GitOps PR-approval model used for IAC

## Security & Governance

- Centralized secrets management via Azure Key Vault, with no secrets ever committed to repos
- RBAC enforced consistently across AKS, ACR, and the IAC pipeline, mapped to org/team structure
- Guardrails (policy-as-code) baked into both the IAC pipeline and the developer self-service portal, so non-compliant infra is rejected early rather than caught after the fact
- Audit trail for every infra change, since everything flows through a PR with recorded approvals