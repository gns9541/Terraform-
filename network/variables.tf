# 테라폼 동작 시점에 값을 주입할 변수들을 정의
# type만 정의되어 있으면 값을 입력 받아야 하는 required 변수
# default가 정의되어 있으면 값을 입력받지 않을 경우 default 로 입력받은 값을 사용

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
  default = "ap-northeast-2"
}

variable "bucket_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "elb_account_id" {
  type = string
  default = "600734575887"
}

variable "domain" {
  type = string
}

variable "env_suffix" {
  type = string
  default = ""
}

variable "tpl_path" {
  type = string
}

variable "container_port" {
  type = number
  default = 80
}

variable "host_port" {
  type = number
  default = 80
}

variable "az_count" {
  type    = number
  default = 4
}

variable "scaling_max_capacity" {
  type = number
  default = 3
}

variable "scaling_min_capacity" {
  type = number
  default = 1
}

variable "cpu_or_memory_limit" {
  type = number
  default = 70
}
