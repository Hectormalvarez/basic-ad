output "lab_group_name" {
  description = "Add your IAM User to this Group to manage the lab"
  value       = aws_iam_group.lab_admins.name
}

output "setup_instruction" {
  value = "Run: aws iam add-user-to-group --user-name YOUR_USER --group-name ${aws_iam_group.lab_admins.name}"
}