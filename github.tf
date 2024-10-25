data "github_repository" "default" {
  name = var.terraform.github.repository
}

data "github_user" "default" {
  username = var.terraform.github.username
}
