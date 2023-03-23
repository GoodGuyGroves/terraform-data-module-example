# These two data sources return data based on the AWS account that this terraform code runs against
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}