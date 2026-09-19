variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster to install the CloudWatch Observability add-on into"
}

# Both come from the eks module's outputs — required to build the IRSA
# trust policy for the add-on's cloudwatch-agent ServiceAccount.
variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the cluster's IAM OIDC identity provider"
}

variable "oidc_provider" {
  type        = string
  description = "The cluster's OIDC issuer host (no https:// prefix)"
}

# The ELB fronting ingress-nginx auto-generates its name from its DNS
# hostname (e.g. "abc123...-456.us-east-1.elb.amazonaws.com" -> "abc123...") —
# there's no separate "load balancer name" available from the ingress-nginx
# module today, so this module derives it from the hostname instead of
# needing a second output threaded through.
variable "ingress_elb_hostname" {
  type        = string
  description = "DNS hostname of the Classic ELB created for the ingress-nginx LoadBalancer Service"
}

variable "node_cpu_alarm_threshold" {
  type        = number
  default     = 80
  description = "Node CPU utilization percentage that triggers an alarm"
}

variable "node_memory_alarm_threshold" {
  type        = number
  default     = 80
  description = "Node memory utilization percentage that triggers an alarm"
}

variable "pod_restart_alarm_threshold" {
  type        = number
  default     = 3
  description = "Total container restarts across the cluster, within one evaluation period, that triggers an alarm"
}

variable "alarm_email" {
  type        = string
  default     = ""
  description = "Optional email address to subscribe to the alerts SNS topic. Leave empty to skip the subscription (you can still see/act on alarms via the console, or subscribe something else to the topic later — e.g. Slack/Teams/Telegram for the bonus ChatOps step)."
}
