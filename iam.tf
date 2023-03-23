# This data source relies on a naming convention coupled with using the environment name to find a user you're expecting should exist
data "aws_iam_user" "github_actions" {
    count = var.acc_env_short != null ? 1 : 0
    user_name = format("%s-Github_Actions_Deploy", var.acc_env_short)
}