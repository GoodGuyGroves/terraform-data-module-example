# This data source relies on a tagging convention where the VPC you are looking for must be tagged with the name of the team that owns it
data "aws_vpcs" "this" {
  # Here we check var.acc_env directly to see if it is not `null`, then we know it has been set by the user
  count = var.acc_env != null && var.vpc_owner != null ? 1 : 0
  tags = {
    owner       = var.vpc_owner
    environment = var.acc_env
  }
}

data "aws_vpc" "this" {
  # Here we use coalesce() to check if var.acc_env is set
  count = coalesce(var.acc_env, false) ? 1 : 0
  id    = one(one(data.aws_vpcs.this[*]).ids[*])
}