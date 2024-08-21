# Public Subnet 내부에 Application Load Balancer를 구성하고 ACM에 등록 되어있는 인증서를 443 HTTPS 프로토콜에 적용
# 80 포트로 요청이 올 경우 443 포트로 리다이렉션
# aws_lb_target_group: forward 요청에 관한 프로토콜, 전송 포트, 헬스체크 규칙 등에 관한 설정


# Application Load Balancer 생성
# 퍼블릭 서브넷에 배치되며, 외부에서 접근 가능 (internal = false)
# 보안 그룹 연결
# 액세스 로그가 S3 버킷에 저장되도록 설정

resource "aws_alb" "staging" {
  name               = "alb-${var.env_suffix}"
  subnets            = aws_subnet.public.*.id
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  internal           = false

  access_logs {
    bucket  = aws_s3_bucket.log_storage.id
    prefix  = "frontend-alb"
    enabled = true
  }

  tags = {
    Environment = "staging"
    Application = var.app_name
  }
}

# HTTPS 리스너 설정 (포트 443)
# SSL 인증서(ACM)를 연결
# 기본 작업으로 트래픽을 target group으로 전달

resource "aws_lb_listener" "https_forward" {
  load_balancer_arn = aws_alb.staging.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.staging.id
  }
}

# HTTP 리스너 설정 (포트 80)
# HTTP 트래픽을 HTTPS로 리다이렉트하는 기본 작업 설정

resource "aws_lb_listener" "http_forward" {
  load_balancer_arn = aws_alb.staging.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB의 대상 그룹을 생성
#   대상 유형이 "ip"로 설정되어 있어, Fargate 작업과 호환
#   헬스 체크 설정이 포함:
#     - 120초 간격으로 체크
#     - "/" 경로로 요청
#     - 60초 타임아웃
#     - 200 응답 코드를 정상으로 간주
#     - 5번의 연속 성공/실패로 상태 변경

resource "aws_lb_target_group" "staging" {
  vpc_id                = aws_vpc.cluster_vpc.id
  name                  = "service-alb-tg-${var.env_suffix}"
  port                  = var.host_port
  protocol              = "HTTP"
  target_type           = "ip"
  deregistration_delay  = 30

  health_check {
    interval            = 120
    path                = "/"
    timeout             = 60
    matcher             = "200"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SSL 인증서(ACM)가 미리 생성되어 있어야 함
# S3 버킷(log_storage)이 미리 생성되어 있어야 함