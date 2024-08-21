# ECR 레포지토리를 생성하고 ECS 컨테이너에 이미지를 배포 할 수 있도록 구성
# 도커 이미지를 저장할 레포지토리를 생성하고 policy를 설정

# ECR 리포지토리를 생성
#   - name: "nodebb/service_${var.env_suffix}"로 설정되어 환경별로 고유한 이름
#   - image_tag_mutability: "MUTABLE"로 설정되어 이미지 태그를 덮어쓸 수 있음
#   - image_scanning_configuration:
#     - scan_on_push = false로 설정되어 이미지 푸시 시 자동 스캔 비활성화

resource "aws_ecr_repository" "repo" {
  name = "nodebb/service_${var.env_suffix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# ECR 리포지토리의 라이프사이클 정책을 정의
#  a. 첫 번째 규칙 (rulePriority: 1):
#   "latest" 태그가 붙은 이미지 중 하나만 유지
#  b. 두 번째 규칙 (rulePriority: 2):
#   모든 태그를 포함하여 최근 2개의 이미지만 유지

resource "aws_ecr_lifecycle_policy" "repo-policy" {
  repository = aws_ecr_repository.repo.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep image deployed with tag latest",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["latest"],
          "countType": "imageCountMoreThan",
          "countNumber": 1
        },
        "action": {
          "type": "expire"
        }
      },
      {
        "rulePriority": 2,
        "description": "Keep last 2 any images",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": 2
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}
