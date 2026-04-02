variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment identifier (e.g. staging, production)"
}

variable "project" {
  description = "Project/company name used for tagging and naming resources"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the public subnets (ALB + NAT Gateway), one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for the private subnets (EC2 instances), one per AZ"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the subnets (must match the number of CIDRs)"
  type        = list(string)
}
