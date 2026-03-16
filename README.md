# Prometheus — Terraform Module Collection

A curated collection of production-ready, reusable Terraform modules for provisioning cloud infrastructure. Each module is designed to be consumed independently or composed together to build complete environments.

## Modules

Refer to each module's own `README.md` for detailed documentation on inputs, outputs, usage examples, and requirements.

| Module | Description | Docs |
|--------|-------------|------|
| **[aws/vpc](aws/vpc/)** | AWS VPC with public/private subnets, NAT gateways, internet gateway, and route tables | [README](aws/vpc/README.md) |
| **[aws/eks](aws/eks/)** | AWS EKS cluster with managed node groups, IAM, OIDC (IRSA), Fargate, and addons | [README](aws/eks/README.md) |
| **[aws/ecs](aws/ecs/)** | AWS ECS cluster with services, Fargate/EC2 capacity providers, optional ALB, auto scaling, and CloudWatch logging | [README](aws/ecs/README.md) |
| **[aws/ec2](aws/ec2/)** | AWS EC2 instances with Launch Templates, IAM, security groups, optional ASG, EBS, and EIP | [README](aws/ec2/README.md) |

## Quick Start

Reference any module directly from this repository using a Git source with a version tag:

```hcl
module "example" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//<provider>/<module>?ref=v1.1.0"

  # module inputs...
}
```

> Pin modules to a specific version tag (e.g. `?ref=v1.1.0`) to avoid unexpected changes.

## Repository Structure

```
prometheus/
├── <provider>/
│   └── <module>/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── README.md
│       └── examples/
│           ├── dev/
│           └── production/
├── CHANGELOG.md
├── version.txt
└── README.md
```

Modules are organized by **cloud provider** (e.g. `aws/`) and then by **service** (e.g. `vpc/`, `eks/`, `ecs/`). Each module is self-contained with its own `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md`.

## Requirements

| Dependency | Version |
|------------|---------|
| [Terraform](https://www.terraform.io/) | >= 1.5.0 |

Individual modules may require additional providers — see each module's `versions.tf` for specifics.

## Versioning

This repository uses [Release Please](https://github.com/googleapis/release-please) for automated semantic versioning. Releases are created on push to `master` based on [Conventional Commits](https://www.conventionalcommits.org/):

| Commit prefix | Release type | Example |
|---------------|-------------|---------|
| `feat:` | Minor | `feat: add RDS module` |
| `fix:` | Patch | `fix: correct subnet CIDR calculation` |
| `feat!:` or `BREAKING CHANGE:` | Major | `feat!: rename vpc_name to name` |

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

## Contributing

1. Create a feature branch from `dev`
2. Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages
3. Each module should include:
   - `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
   - A `README.md` documenting inputs, outputs, and usage
   - `examples/` with at least a `dev` and `production` configuration
4. Open a pull request against `dev`

## License

This project is maintained by [Praganoid Studio](https://github.com/praganoid-studio).
