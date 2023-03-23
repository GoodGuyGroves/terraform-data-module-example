variable "acc_env" {
  type        = string
  description = "The environment that uses this account, eg production, development, etc"
  nullable    = true
  default     = null
}

variable "acc_env_short" {
  type        = string
  description = "The shortened version of the environment that uses this account, eg prod, dev, etc"
  nullable    = true
  default     = null
}

variable "vpc_owner" {
  type        = string
  description = "The team that owns the VPC you want to query"
  nullable    = true
  default     = null
}