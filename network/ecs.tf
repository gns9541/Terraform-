# ECS 작업 실행 역할을 위한 IAM 정책 문서를 정의
# ECS 작업이 AWS 서비스를 대신하여 작업을 수행할 수 있도록 

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# 위에서 정의한 정책 문서를 사용하여 IAM 역할 생성
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-staging-execution-role-${var.env_suffix}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

# 생성된 IAM 역할에 AmazonECSTaskExecutionRolePolicy를 연결
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS 작업 정의를 위한 템플릿 파일 렌더링
# ECR 리포지토리 URL, 컨테이너 포트 등 다양한 변수를 템플릿에 주입
data "template_file" "service" {
  template = file(var.tpl_path)

  vars = {
    region             = var.region
    aws_ecr_repository = aws_ecr_repository.repo.repository_url
    tag                = "latest"
    container_port     = var.container_port
    host_port          = var.host_port
    app_name           = var.app_name
    env_suffix         = var.env_suffix
  }
}

# ECS 작업 정의를 생성
# Fargate 호환성, 네트워크 모드, CPU/메모리 요구사항 등을 지정
# 렌더링된 컨테이너 정의를 사용
resource "aws_ecs_task_definition" "service" {
  family                   = "service-staging-${var.env_suffix}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.service.rendered

  tags = {
    Environment = "staging"
    Application = var.app_name
  }
}

# ECS 클러스터를 생성
resource "aws_ecs_cluster" "staging" {
  name = "service-ecs-cluster-${var.env_suffix}"
}

# ECS 서비스를 생성하고 설정
# Fargate에서 실행되도록 설정
# 네트워크 설정, 로드 밸런서 연결, 원하는 작업 수 등을 지정
# 가용 영역 수만큼의 작업을 실행하도록 설정

resource "aws_ecs_service" "staging" {
  name                  = "staging"
  cluster               = aws_ecs_cluster.staging.id
  task_definition       = aws_ecs_task_definition.service.arn
  desired_count         = length(data.aws_availability_zones.available.names)
  force_new_deployment  = true
  launch_type           = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.staging.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.https_forward,
    aws_lb_listener.http_forward,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
  ]

  tags = {
    Environment = "staging"
    Application = var.app_name
  }
}
