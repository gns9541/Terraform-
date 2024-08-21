# Load Balancer와 ECS 인스턴스에 관한 보안그룹 규칙 설정
# Load Balancer는 80, 443 포트 요청만을 허용하고 ECS는 80 포트 요청만 허용

# 로드 밸런서(ALB)를 위한 보안 그룹을 생성
#   - 인바운드 규칙:
#     - var.host_port로의 TCP 트래픽 허용 (HTTP)
#     - 443 포트로의 TCP 트래픽 허용 (HTTPS)
#     - IPv4와 IPv6 모두에서의 접근을 허용
#   - 아웃바운드 규칙:
#     - 모든 아웃바운드 트래픽 허용 (0.0.0.0/0 및 ::/0)

resource "aws_security_group" "lb" {
  vpc_id = aws_vpc.cluster_vpc.id
  name = "lb-sg-${var.env_suffix}"

  ingress {
    from_port         = var.host_port
    protocol          = "tcp"
    to_port           = var.host_port
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  ingress {
    from_port         = 443
    protocol          = "tcp"
    to_port           = 443
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# ECS 작업을 위한 보안 그룹을 생성
#   - 인바운드 규칙:
#     - var.host_port에서 var.container_port로의 TCP 트래픽을 허용
#   - 아웃바운드 규칙:
#     - 모든 아웃바운드 트래픽을 허용 (0.0.0.0/0)

resource "aws_security_group" "ecs_tasks" {
  vpc_id = aws_vpc.cluster_vpc.id
  name = "ecs-tasks-sg-${var.env_suffix}"

  ingress {
    from_port       = var.host_port
    protocol        = "tcp"
    to_port         = var.container_port
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port     = 0
    protocol      = "-1"
    to_port       = 0
    cidr_blocks   = ["0.0.0.0/0"]
  }
}
