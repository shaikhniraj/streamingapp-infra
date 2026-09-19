output "sns_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "SNS topic that every alarm in this module publishes to — subscribe email/Slack/Teams/Telegram to it here or later for the ChatOps bonus step"
}

output "cloudwatch_agent_role_arn" {
  value       = aws_iam_role.cloudwatch_agent.arn
  description = "IAM role assumed by the CloudWatch Observability add-on's agent ServiceAccount"
}

output "addon_name" {
  value       = aws_eks_addon.cloudwatch_observability.addon_name
  description = "Name of the installed EKS add-on, for `aws eks describe-addon` / troubleshooting"
}
