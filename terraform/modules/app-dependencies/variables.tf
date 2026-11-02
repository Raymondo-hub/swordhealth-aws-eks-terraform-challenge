variable "name" {
  type = string
}

variable "queue_visibility_timeout_seconds" {
  type    = number
  default = 60
}

variable "queue_message_retention_seconds" {
  type    = number
  default = 1209600
}

variable "tags" {
  type    = map(string)
  default = {}
}
