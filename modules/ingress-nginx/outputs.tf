output "load_balancer_hostname" {
  description = "DNS hostname of the AWS Network Load Balancer fronting the ingress controller"
  value       = try(data.kubernetes_service.ingress_nginx_controller.status[0].load_balancer[0].ingress[0].hostname, "not yet available — re-run 'terragrunt output' shortly")
}