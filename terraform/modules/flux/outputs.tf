output "flux_namespace" { value = flux_bootstrap_git.this.namespace }
output "flux_repository" { value = flux_bootstrap_git.this.repository_files }
output "deploy_key_id" { value = github_repository_deploy_key.flux.id }
