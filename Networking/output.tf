output "public_subnet_id" {
    value = aws_subnet.public_subnet.id
}

output "default_security_group_id" {
    value = aws_default_security_group.default_security_group.id
}