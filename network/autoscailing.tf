# ECS 클러스터가 CPU / Memory 사용률에 따라 CPU / Memory Limit, 최소 / 최대 테스크 갯수 등을 설정하여 
# ECS task 증가 or 감소 시키는 정책을 정의, 요청량에 따라 유동적으로 컨테이너를 사용 할 수 있도록 구성


# ECS 서비스의 Auto Scaling 대상을 정의
#  max_capacity와 min_capacity를 변수로 설정하여 스케일링 범위를 지정
#  resource_id는 ECS 클러스터와 서비스 이름을 조합하여 설정
#  scalable_dimension과 service_namespace는 ECS 서비스 스케일링에 필요한 값으로 설정

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.scaling_max_capacity
  min_capacity       = var.scaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.staging.name}/${aws_ecs_service.staging.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# 메모리 사용률 기반의 Auto Scaling 정책을 정의
#  policy_type이 "TargetTrackingScaling"으로 설정되어 있어, 목표 추적 스케일링 방식을 사용
#  ECSServiceAverageMemoryUtilization 지표를 사용하여 메모리 사용률을 모니터링
#  target_value는 var.cpu_or_memory_limit 변수로 설정되어 스케일링 임계값을 지정

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = var.cpu_or_memory_limit
  }
}

# CPU 사용률 기반의 Auto Scaling 정책을 정의
# 메모리 정책과 유사하지만 ECSServiceAverageCPUUtilization 지표를 사용
# target_value가 60 -> CPU 사용률이 60%를 넘으면 스케일 아웃이 트리거

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}
