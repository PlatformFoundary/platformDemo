locals {
  github_known_hosts = join("\n", [
    "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=",
    "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl",
    "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=",
  ])
}

# ── flux-system namespace ─────────────────────────────────────────────────────
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }
  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "kubernetes_secret" "flux_ssh" {
  metadata {
    name      = "ssh-credentials"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }
  data = {
    identity       = var.ssh_private_key
    "identity.pub" = var.ssh_public_key
    known_hosts    = local.github_known_hosts
  }
  depends_on = [kubernetes_namespace.flux_system]
}

# ── GitHub deploy key ─────────────────────────────────────────────────────────
resource "github_repository_deploy_key" "flux" {
  title      = var.key_title
  repository = var.github_repo
  key        = var.ssh_public_key
  read_only  = false
}

# ── Flux bootstrap ────────────────────────────────────────────────────────────
resource "flux_bootstrap_git" "this" {
  path        = var.flux_target_path
  secret_name = kubernetes_secret.flux_ssh.metadata[0].name

  components_extra = ["image-reflector-controller", "image-automation-controller"]

  depends_on = [
    github_repository_deploy_key.flux,
    kubernetes_secret.flux_ssh,
  ]
}
