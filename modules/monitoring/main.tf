# CloudWatch Observability EKS add-on — installs the CloudWatch Agent
# (Container Insights metrics) and Fluent Bit (log forwarding to CloudWatch
# Logs) as DaemonSets, with no application code changes required. Uses the
# classic IRSA pattern (not the newer EKS Pod Identity option) to match how
# modules/eks already grants the EBS CSI driver its own scoped role.

# WHO is allowed to assume this role: only the "cloudwatch-agent"
# ServiceAccount that the add-on creates in the "amazon-cloudwatch"
# namespace, proven via a signed OIDC token from this cluster's own OIDC
# provider — per AWS's documented IRSA install path for this add-on
# (see: Install the Amazon CloudWatch Observability EKS add-on > Option 3).
data "aws_iam_policy_document" "cloudwatch_agent_irsa_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_agent" {
  name               = "${var.project}-${var.environment}-cloudwatch-agent"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_agent_irsa_trust.json
}

# AWS's own managed policy — covers cloudwatch:PutMetricData, logs:*, and the
# EC2 describe calls the agent needs for tagging/metadata enrichment.
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = aws_iam_role.cloudwatch_agent.arn

  # Don't fight kubectl-applied config for fields EKS doesn't manage itself.
  resolve_conflicts_on_update = "PRESERVE"
}

# A single topic for every alarm below — one place to attach an email,
# Slack, Teams, or Telegram subscription (the bonus ChatOps step reuses
# this same topic rather than creating a separate one).
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# --- Container Insights alarms (published by the add-on's CloudWatch Agent) ---

resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.project}-${var.environment}-node-cpu-high"
  alarm_description   = "EKS worker node CPU utilization is above ${var.node_cpu_alarm_threshold}% — the cluster may need more/bigger nodes."
  namespace           = "ContainerInsights"
  metric_name         = "node_cpu_utilization"
  dimensions          = { ClusterName = var.cluster_name }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.node_cpu_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  depends_on = [aws_eks_addon.cloudwatch_observability]
}

resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  alarm_name          = "${var.project}-${var.environment}-node-memory-high"
  alarm_description   = "EKS worker node memory utilization is above ${var.node_memory_alarm_threshold}%."
  namespace           = "ContainerInsights"
  metric_name         = "node_memory_utilization"
  dimensions          = { ClusterName = var.cluster_name }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.node_memory_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  depends_on = [aws_eks_addon.cloudwatch_observability]
}

resource "aws_cloudwatch_metric_alarm" "pod_restarts_high" {
  alarm_name          = "${var.project}-${var.environment}-pod-restarts-high"
  alarm_description   = "More than ${var.pod_restart_alarm_threshold} container restarts across the cluster in one 5-minute window — likely a crash-looping service."
  namespace           = "ContainerInsights"
  metric_name         = "pod_number_of_container_restarts"
  dimensions          = { ClusterName = var.cluster_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.pod_restart_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  depends_on = [aws_eks_addon.cloudwatch_observability]
}

# --- ELB alarms (published automatically by the ingress Classic ELB, no
# add-on needed) ---

locals {
  # The in-tree AWS cloud provider names the ELB after the first label of
  # its own generated DNS hostname (verified against the live LB: DNSName
  # "a00862b...-2036017027.us-east-1.elb.amazonaws.com" -> LoadBalancerName
  # "a00862b...") — there's no separate name to thread through from the
  # ingress-nginx module today.
  ingress_elb_name = split("-", var.ingress_elb_hostname)[0]
}

resource "aws_cloudwatch_metric_alarm" "ingress_elb_unhealthy_hosts" {
  alarm_name          = "${var.project}-${var.environment}-ingress-elb-unhealthy-hosts"
  alarm_description   = "One or more ingress-nginx backend instances are failing the ELB health check."
  namespace           = "AWS/ELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = { LoadBalancerName = local.ingress_elb_name }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ingress_elb_backend_5xx" {
  alarm_name          = "${var.project}-${var.environment}-ingress-elb-backend-5xx"
  alarm_description   = "The app is returning a burst of 5xx responses through the ingress ELB."
  namespace           = "AWS/ELB"
  metric_name         = "HTTPCode_Backend_5XX"
  dimensions          = { LoadBalancerName = local.ingress_elb_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
