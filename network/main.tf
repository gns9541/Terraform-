# 인프라를 배포할 프로바이더와 사용 가능 버전을 지정, 각 프로바이더를 사용하기 위한 기본 credentials 정보 바인딩

# Terraform 자체의 설정을 정의
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# AWS 프로바이더 구성
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}