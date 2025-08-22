# AWS CLI 배포 가이드

AWS CLI를 사용하여 마이크로서비스를 AWS ECS에 배포하는 방법입니다.

## 📋 사전 준비사항

### 1. 필수 도구 설치
```bash
# AWS CLI 설치
# https://aws.amazon.com/cli/

# Docker 설치 (컨테이너 이미지 빌드용)
# https://www.docker.com/

# Git 설치
# https://git-scm.com/
```

### 2. AWS 설정
```bash
# AWS CLI 설정
aws configure

# 입력할 정보:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: ap-northeast-2
# Default output format: json
```

### 3. AWS 권한 확인
- ECS Full Access
- EC2 Full Access
- ECR Full Access
- IAM Full Access
- CloudWatch Full Access

## 🚀 빠른 시작

### 1. 리소스 정보 수집
```bash
cd deployment-guides/aws-cli

# 리소스 정보 수집 스크립트 실행
./collect-aws-resources.sh
```

### 2. 배포 실행
```bash
# 배포 스크립트 실행
./deploy-aws.sh
```

## 📁 파일 구조

```
aws-cli/
├── README.md                    # 이 파일
├── collect-aws-resources.sh     # 리소스 정보 수집 스크립트
└── deploy-aws.sh               # 배포 스크립트
```

## 🔧 수동 배포 단계

### 1. ECR Repository 생성
```bash
# User Service Repository
aws ecr create-repository \
    --repository-name tf-user-service \
    --region ap-northeast-2

# Store Service Repository
aws ecr create-repository \
    --repository-name tf-store-service \
    --region ap-northeast-2

# Booking Service Repository
aws ecr create-repository \
    --repository-name tf-booking-service \
    --region ap-northeast-2
```

### 2. ECS Cluster 생성
```bash
aws ecs create-cluster \
    --cluster-name tf-microservices-cluster \
    --region ap-northeast-2 \
    --capacity-providers FARGATE \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1
```

### 3. VPC 및 네트워킹 설정
```bash
# 기본 VPC 정보 확인
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ap-northeast-2)

# Subnet 정보 확인
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text --region ap-northeast-2)
```

### 4. Security Groups 생성
```bash
# ALB Security Group
ALB_SG_ID=$(aws ec2 create-security-group \
    --group-name tf-alb-sg \
    --description "Security group for ALB" \
    --vpc-id $VPC_ID \
    --region ap-northeast-2 \
    --query 'GroupId' --output text)

# ECS Security Group
ECS_SG_ID=$(aws ec2 create-security-group \
    --group-name tf-ecs-sg \
    --description "Security group for ECS tasks" \
    --vpc-id $VPC_ID \
    --region ap-northeast-2 \
    --query 'GroupId' --output text)

# Security Group 규칙 설정
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region ap-northeast-2

aws ec2 authorize-security-group-ingress \
    --group-id $ECS_SG_ID \
    --protocol tcp \
    --port 8080-8085 \
    --source-group $ALB_SG_ID \
    --region ap-northeast-2
```

### 5. Application Load Balancer 생성
```bash
SUBNET_1=$(echo $SUBNET_IDS | cut -d' ' -f1)
SUBNET_2=$(echo $SUBNET_IDS | cut -d' ' -f2)

ALB_ARN=$(aws elbv2 create-load-balancer \
    --name tf-alb \
    --subnets $SUBNET_1 $SUBNET_2 \
    --security-groups $ALB_SG_ID \
    --region ap-northeast-2 \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)
```

### 6. Target Groups 생성
```bash
# User Service Target Group
USER_TG_ARN=$(aws elbv2 create-target-group \
    --name tf-user-tg \
    --protocol HTTP \
    --port 8085 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path /actuator/health \
    --region ap-northeast-2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

# Store Service Target Group
STORE_TG_ARN=$(aws elbv2 create-target-group \
    --name tf-store-tg \
    --protocol HTTP \
    --port 8081 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path /actuator/health \
    --region ap-northeast-2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

# Booking Service Target Group
BOOKING_TG_ARN=$(aws elbv2 create-target-group \
    --name tf-booking-tg \
    --protocol HTTP \
    --port 8080 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path /actuator/health \
    --region ap-northeast-2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text)
```

### 7. Task Definition 생성
```bash
# User Service Task Definition
cat > user-service-task-definition.json << EOF
{
  "family": "tf-user-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "user-service",
      "image": "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/tf-user-service:latest",
      "portMappings": [
        {
          "containerPort": 8085,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "prod"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/tf-user-service",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://user-service-task-definition.json --region ap-northeast-2
```

### 8. ECS Service 생성
```bash
# User Service
aws ecs create-service \
    --cluster tf-microservices-cluster \
    --service-name tf-user-service \
    --task-definition tf-user-service \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$USER_TG_ARN,containerName=user-service,containerPort=8085" \
    --region ap-northeast-2
```

## 📊 모니터링 및 로그

### 1. 서비스 상태 확인
```bash
# ECS 서비스 목록
aws ecs list-services --cluster tf-microservices-cluster --region ap-northeast-2

# 서비스 상세 정보
aws ecs describe-services \
    --cluster tf-microservices-cluster \
    --services tf-user-service \
    --region ap-northeast-2
```

### 2. 로그 확인
```bash
# CloudWatch 로그 그룹 확인
aws logs describe-log-groups --log-group-name-prefix "/ecs/tf-" --region ap-northeast-2

# 로그 스트림 확인
aws logs describe-log-streams \
    --log-group-name "/ecs/tf-user-service" \
    --region ap-northeast-2

# 로그 조회
aws logs get-log-events \
    --log-group-name "/ecs/tf-user-service" \
    --log-stream-name "ecs/user-service/..." \
    --region ap-northeast-2
```

### 3. ALB 상태 확인
```bash
# ALB 정보
aws elbv2 describe-load-balancers --names tf-alb --region ap-northeast-2

# Target Group 상태
aws elbv2 describe-target-health \
    --target-group-arn $USER_TG_ARN \
    --region ap-northeast-2
```

## 🔄 업데이트 및 관리

### 1. 서비스 업데이트
```bash
# 새 이미지로 서비스 업데이트
aws ecs update-service \
    --cluster tf-microservices-cluster \
    --service tf-user-service \
    --force-new-deployment \
    --region ap-northeast-2
```

### 2. 서비스 스케일링
```bash
# 서비스 스케일 업
aws ecs update-service \
    --cluster tf-microservices-cluster \
    --service tf-user-service \
    --desired-count 4 \
    --region ap-northeast-2
```

### 3. 서비스 삭제
```bash
# 서비스 삭제
aws ecs delete-service \
    --cluster tf-microservices-cluster \
    --service tf-user-service \
    --force \
    --region ap-northeast-2
```

## 🛠️ 문제 해결

### 1. 일반적인 오류

#### 권한 오류
```bash
# IAM 권한 확인
aws sts get-caller-identity

# 필요한 정책 추가
aws iam attach-user-policy \
    --user-name YOUR_USER \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### 리소스 중복 오류
```bash
# 기존 리소스 확인
aws ecs describe-clusters --clusters tf-microservices-cluster --region ap-northeast-2

# 기존 리소스 삭제 후 재생성
aws ecs delete-cluster --cluster tf-microservices-cluster --region ap-northeast-2
```

#### 네트워킹 오류
```bash
# VPC 및 Subnet 확인
aws ec2 describe-vpcs --region ap-northeast-2
aws ec2 describe-subnets --region ap-northeast-2

# Security Group 규칙 확인
aws ec2 describe-security-groups --group-ids $ECS_SG_ID --region ap-northeast-2
```

### 2. 디버깅

#### 상세 로그 확인
```bash
# ECS 서비스 이벤트 확인
aws ecs describe-services \
    --cluster tf-microservices-cluster \
    --services tf-user-service \
    --region ap-northeast-2 \
    --query 'services[0].events'
```

#### Task 로그 확인
```bash
# 실행 중인 Task 확인
aws ecs list-tasks \
    --cluster tf-microservices-cluster \
    --service-name tf-user-service \
    --region ap-northeast-2

# Task 상세 정보
aws ecs describe-tasks \
    --cluster tf-microservices-cluster \
    --tasks TASK_ARN \
    --region ap-northeast-2
```

## 📚 유용한 명령어

### 리소스 정보 조회
```bash
# ECS Cluster 정보
aws ecs describe-clusters --clusters tf-microservices-cluster --region ap-northeast-2

# ECR Repository 정보
aws ecr describe-repositories --region ap-northeast-2

# ALB 정보
aws elbv2 describe-load-balancers --names tf-alb --region ap-northeast-2

# Target Group 정보
aws elbv2 describe-target-groups --region ap-northeast-2
```

### 비용 확인
```bash
# CloudWatch 메트릭 확인
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ClusterName,Value=tf-microservices-cluster \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-02T00:00:00Z \
    --period 3600 \
    --statistics Average \
    --region ap-northeast-2
```

## ⚠️ 주의사항

1. **비용 관리**: AWS 리소스 사용료가 발생합니다
2. **보안**: 프로덕션 환경에서는 적절한 IAM 권한 설정이 필요합니다
3. **백업**: 중요한 데이터는 별도 백업 전략을 수립하세요
4. **모니터링**: CloudWatch 알람 설정을 권장합니다
5. **테스트**: 프로덕션 배포 전에 개발/스테이징 환경에서 충분히 테스트하세요

## 🆘 지원

문제가 발생하면:
1. 이 문서의 문제 해결 섹션 확인
2. AWS CLI 명령어에 `--debug` 옵션 추가
3. AWS Support 또는 커뮤니티 포럼 활용
