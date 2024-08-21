# 기존 Route 53 호스팅 영역의 정보
#  name: var.domain 변수에 지정된 도메인 이름을 사용합
#  private_zone = false: 공개 호스팅 영역을 사용함

data "aws_route53_zone" "front" {
  name         = var.domain
  private_zone = false
}

애플리케이션의 메인 A 레코드 생성
#   - zone_id: 위에서 가져온 호스팅 영역 ID를 사용
#   - name: var.domain 변수로 지정된 도메인 이름을 사용
#   - type: "A" 레코드 타입을 사용
#   - alias: ALB(Application Load Balancer)로 트래픽을 라우팅하는 별칭 레코드를 설정
#     - name: ALB의 DNS 이름을 지정
#     - zone_id: ALB의 호스팅 영역 ID를 지정
#     - evaluate_target_health: true로 설정하여 ALB의 상태를 확인

resource "aws_route53_record" "front" {
  zone_id = data.aws_route53_zone.front.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_alb.staging.dns_name
    zone_id                = aws_alb.staging.zone_id
    evaluate_target_health = true
  }
}

#  ACM 인증서 검증을 위한 DNS 레코드를 생성
#   - name, type, records: ACM에서 제공하는 검증 정보를 사용
#   - zone_id: 메인 도메인의 호스팅 영역 ID를 사용
#   - ttl: 60초로 설정되어 있어, DNS 변경사항이 빠르게 전파

resource "aws_route53_record" "cert_validation" {
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.front.zone_id
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}