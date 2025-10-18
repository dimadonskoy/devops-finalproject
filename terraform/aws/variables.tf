# AWS Terraform Variables

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ai-chatbot"
}

variable "instance_type" {
  description = "EC2 instance type (free tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "public_key" {
  description = "Public key for SSH access"
  type        = string
}

variable "private_key_path" {
  description = "Path to private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default = {
    Project     = "AI-Chatbot"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
