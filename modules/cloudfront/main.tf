data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "main" {

  # checkov:skip=CKV_AWS_86:access log richiedono bucket S3 dedicato, costo>beneficio in ambiente demo
  # checkov:skip=CKV_AWS_174:il certificato di default CloudFront non consente di impostare la minimum protocol version; servirebbe un certificato ACM custom (quindi un dominio)
  # checkov:skip=CKV2_AWS_42:certificato di default per assenza di dominio dedicato; scelta documentata nel README
  # checkov:skip=CKV_AWS_68:WAF fuori scope per costo; in roadmap v2
  # checkov:skip=CKV2_AWS_47:vedi CKV_AWS_68, nessun WAF associato
  # checkov:skip=CKV_AWS_310:origine singola per scelta architetturale; il failover richiederebbe un secondo ALB
  # checkov:skip=CKV_AWS_305:n8n e' un'applicazione dinamica, non un sito statico con documento radice
  # checkov:skip=CKV_AWS_374:nessuna restrizione geografica: accesso previsto da qualsiasi paese

  enabled = true
  comment = "${var.project_name} - n8n"

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }


}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}