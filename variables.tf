variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "docker_images" {
  description = "List of Docker images for cheese app"
  type        = list(string)
}
