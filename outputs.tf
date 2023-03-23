# Not using `try()` because this should always return something
output "aws_region" {
  description = "The region of the current AWS account"
  value       = data.aws_region.current.name
}

# Not using `try()` because this should always return something
output "aws_account_id" {
  description = "The account ID of the current AWS account"
  value       = data.aws_caller_identity.current.account_id
}

# This output is for one specific value
output "vpc_id" {
  description = "The ID of the VPC you're querying"
  value       = try(one(one(data.aws_vpcs.this[*]).ids[*]), null)
}

# This output contains a lot of information, including the VPC ID exposed above. You can decide how much data you want to output.
output "aws_vpc" {
  description = "All VPC data"
  value       = try(one(data.aws_vpc.this[*]), null)
}

# This could be for a user we expect to exist that we may want to add additional permissions to
output "github_actions_deploy_user" {
  description = "The IAM user for Github Actions to deploy to this account"
  value = try(one(data.aws_iam_user.github_actions[*]), null)
}
