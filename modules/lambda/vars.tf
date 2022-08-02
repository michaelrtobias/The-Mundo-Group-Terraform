variable "aws_codestarconnections_connection_arn" {}

variable "send_email_queue" {}

variable "send_email_ses_identity" {}

variable "inventory_lambdas" {
  type = map(any)
  default = {
    create-inventory = "create-inventory",
    read-inventory   = "read-inventory",
    update-inventory = "update-inventory",
    delete-inventory = "delete-inventory",
  }
}
