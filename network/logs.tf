# 로드밸런서의 access log를 저장할 S3 버킷과 CloudWatch group을 생성

# ALB 로그를 저장할 S3 버킷 생성
# force_destroy = true 설정으로 Terraform destroy 시 버킷 내 객체도 함께 삭제

resource "aws_s3_bucket" "log_storage" {
  bucket = var.bucket_name
  force_destroy = true
}

# ECS 서비스의 로그를 저장할 CloudWatch 로그 그룹을 생성

resource "aws_cloudwatch_log_group" "service" {
  name = "awslogs-service-staging-${var.env_suffix}"

  tags = {
    Environment = "staging"
    Application = var.app_name
  }
}

# S3 버킷의 ACL을 'private'으로 설정
resource "aws_s3_bucket_acl" "lb-logs-acl" {
  bucket = aws_s3_bucket.log_storage.id
  acl    = "private"
}

# S3 버킷 정책 정의
data "aws_iam_policy_document" "allow-lb" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elb.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/frontend-alb/AWSLogs/${var.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/frontend-alb/AWSLogs/${var.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.elb_account_id}:root"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/frontend-alb/AWSLogs/${var.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}

# 위에서 정의한 정책을 S3 버킷에 적용
resource "aws_s3_bucket_policy" "allow-lb" {
  bucket = aws_s3_bucket.log_storage.id
  policy = data.aws_iam_policy_document.allow-lb.json
}

# S3 버킷의 객체 수명 주기 규칙을 설정
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.log_storage.id

  rule {
    id      = "log_lifecycle_${var.env_suffix}"
    status  = "Enabled"

    expiration {
      days = 10
    }
  }
}
