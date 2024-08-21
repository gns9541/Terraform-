# 도메인에 대한 SSL 인증서를 발급 받는 테라폼 소스코드
# 유효한 도메인 Route 53 호스팅 영역에 등록 사전에 필요

# ACM 인증서를 요청
# domain_name: var.domain 변수에 지정된 도메인에 대한 인증서 생성
# validation_method: "DNS"로 설정되어 있어, DNS 레코드를 통해 도메인 소유권을 검증
# lifecycle: create_before_destroy = true 설정으로, 인증서 갱신 시 새 인증서를 먼저 생성한 후 기존 인증서를 삭제 -> 서비스 중단 방지

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# 생성된 인증서의 검증 과정을 관리
# certificate_arn: 검증할 인증서의 ARN을 지정
# validation_record_fqdns: 검증에 사용될 DNS 레코드의 FQDN을 지정 -> aws_route53_record.cert_validation.fqdn을 참조

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
