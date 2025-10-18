# AWS Terraform Outputs

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_eip.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.app.public_dns
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.app.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_eip.app.public_ip}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.app.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}
