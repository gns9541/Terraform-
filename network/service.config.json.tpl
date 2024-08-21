[
  {
    "name": "${app_name}",
    "image": "${aws_ecr_repository}:${tag}",
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "staging-service",
        "awslogs-group": "awslogs-service-staging-${env_suffix}"
      }
    },
    "portMappings": [
      {
        "containerPort": ${container_port},
        "hostPort": ${host_port},
        "protocol": "tcp"
      }
    ],
    "cpu": 2,
    "environment": [
      {
        "name": "PORT",
        "value": "${host_port}"
      }
    ],
    "ulimits": [
      {
        "name": "nofile",
        "softLimit": 65536,
        "hardLimit": 65536
      }
    ],
    "mountPoints": [],
    "memory": 512,
    "volumesFrom": []
  }
]

1. 컨테이너 기본 설정:
  - name: ${app_name}으로 설정되어 변수를 통해 애플리케이션 이름을 지정
  - image: ${aws_ecr_repository}:${tag}로 설정되어 ECR의 이미지를 사용
  - essential: true로 설정되어 이 컨테이너가 필수적

2. 로깅 설정:
  - awslogs 드라이버를 사용하여 CloudWatch Logs에 로그를 저장
  - 리전, 스트림 접두사, 로그 그룹 이름을 지정

3. 포트 매핑:
  - containerPort와 hostPort를 변수로 설정하여 유연한 포트 설정 가능
  - 프로토콜은 tcp로 설정

4. 리소스 할당:
  - cpu: 2 (CPU 유닛)
  - memory: 512 (MB)

5. 환경 변수:
  - PORT 환경 변수를 hostPort 값으로 설정

6. 시스템 제한:
  - nofile (파일 디스크립터) 제한을 65536으로 설정

7. 기타 설정:
  - mountPoints와 volumesFrom은 빈 배열로 설정되어 있어 추가 볼륨 마운트가 없음