aws_region  = "eu-west-1"
environment = "production"
project     = "sizebay"

vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.0.0/24", "10.2.1.0/24"]
private_subnet_cidrs = ["10.2.2.0/24", "10.2.3.0/24"]
availability_zones   = ["eu-west-1a", "eu-west-1b"]
