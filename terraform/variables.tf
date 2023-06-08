variable "owner" {
  type        = string
  default     = "Regis Martins"
  description = "Name to be used in the Owner tag of the AWS resources"
}

variable "prefix" {
  type        = string
  default     = "owasp"
  description = "The prefix will precede all the resources to be created for easy identification"
}

variable "aws_region" {
  type        = string
  default     = "ca-central-1"
  description = "AWS region to be used in the deployment"
}

variable "cp_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Instance type used for control-plane node EC2 instance"
}

variable "wk_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Instance type used for worker node EC2 instance"
}

variable "wk_instance_count" {
  type        = number
  default     = 1
  description = "Number of Instances for worker node(s) EC2 instance"
}