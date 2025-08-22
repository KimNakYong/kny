# Terraform 배포 가이드

Terraform을 사용하여 마이크로서비스를 AWS ECS에 배포하는 방법입니다.

## 📋 사전 준비사항

### 1. 필수 도구 설치
```bash
# Terraform 설치
# https://www.terraform.io/downloads.html

# AWS CLI 설치
# https://aws.amazon.com/cli/

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

### 1. Terraform 프로젝트 초기화
```bash
cd deployment-guides/terraform
terraform init
```

### 2. 배포 계획 확인
```bash
terraform plan
```

### 3. 배포 실행
```bash
terraform apply
```

### 4. 배포 확인
```bash
terraform output
```

## 📁 파일 구조

```
terraform/
├── README.md                    # 이 파일
├── main.tf                      # 메인 Terraform 설정
├── variables.tf                 # 변수 정의
├── outputs.tf                   # 출력 정의
├── providers.tf                 # 프로바이더 설정
└── versions.tf                  # 버전 제약
```

## 🔧 Terraform 설정 파일

### 1. providers.tf
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
```

### 2. variables.tf
```hcl
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "tf"
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}
```

### 3. main.tf
```hcl
# VPC 및 네트워킹
resource "aws_vpc" "tf_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-microservices-vpc"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "tf_cluster" {
  name = "${var.project_name}-microservices-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-microservices-cluster"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "tf_alb" {
  name               = "${var.project_name}-microservices-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-microservices-alb"
    Environment = var.environment
  }
}
```

### 4. outputs.tf
```hcl
output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = aws_lb.tf_alb.dns_name
}

output "user_service_url" {
  description = "User Service URL"
  value       = "http://${aws_lb.tf_alb.dns_name}/api/users"
}

output "store_service_url" {
  description = "Store Service URL"
  value       = "http://${aws_lb.tf_alb.dns_name}/api/stores"
}

output "booking_service_url" {
  description = "Booking Service URL"
  value       = "http://${aws_lb.tf_alb.dns_name}/api/bookings"
}

output "cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.tf_cluster.name
}
```

## 🔄 Terraform 명령어

### 1. 초기화
```bash
# Terraform 초기화
terraform init

# 특정 프로바이더 버전으로 초기화
terraform init -upgrade
```

### 2. 계획 및 적용
```bash
# 배포 계획 확인
terraform plan

# 배포 계획을 파일로 저장
terraform plan -out=tfplan

# 저장된 계획으로 배포
terraform apply tfplan

# 자동 승인으로 배포
terraform apply -auto-approve
```

### 3. 상태 관리
```bash
# 현재 상태 확인
terraform show

# 상태 파일 확인
terraform state list

# 특정 리소스 상태 확인
terraform state show aws_ecs_cluster.tf_cluster

# 상태 파일 백업
terraform state pull > terraform.tfstate.backup
```

### 4. 리소스 관리
```bash
# 특정 리소스만 배포
terraform apply -target=aws_ecs_cluster.tf_cluster

# 특정 리소스 삭제
terraform destroy -target=aws_ecs_service.user_service

# 전체 리소스 삭제
terraform destroy
```

## 📊 모니터링 및 로그

### 1. Terraform 상태 확인
```bash
# 상태 요약
terraform state list

# 상세 상태
terraform show

# 출력 값 확인
terraform output
```

### 2. AWS 리소스 상태 확인
```bash
# ECS Cluster 상태
aws ecs describe-clusters --clusters tf-microservices-cluster

# ALB 상태
aws elbv2 describe-load-balancers --names tf-alb

# ECR Repository 상태
aws ecr describe-repositories --repository-names tf-user-service
```

### 3. 로그 확인
```bash
# CloudWatch 로그 그룹 확인
aws logs describe-log-groups --log-group-name-prefix "/ecs/tf-"

# 로그 스트림 확인
aws logs describe-log-streams --log-group-name "/ecs/tf-user-service"
```

## 🛠️ 문제 해결

### 1. 일반적인 오류

#### 상태 파일 오류
```bash
# 상태 파일 백업
terraform state pull > terraform.tfstate.backup

# 상태 파일 복원
terraform state push terraform.tfstate.backup

# 상태 파일 새로고침
terraform refresh
```

#### 리소스 충돌 오류
```bash
# 리소스 가져오기
terraform import aws_ecs_cluster.tf_cluster tf-microservices-cluster

# 리소스 이동
terraform state mv aws_ecs_cluster.old_name aws_ecs_cluster.new_name
```

#### 권한 오류
```bash
# IAM 권한 확인
aws sts get-caller-identity

# 필요한 정책 추가
aws iam attach-user-policy --user-name YOUR_USER --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### 2. 디버깅

#### 상세 로그 활성화
```bash
# Terraform 로그 레벨 설정
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# 실행
terraform plan
```

#### 리소스 상태 확인
```bash
# 특정 리소스 상태 확인
terraform state show aws_ecs_cluster.tf_cluster

# 모든 리소스 상태 확인
terraform show
```

## 🔒 보안 고려사항

### 1. 상태 파일 보안
```bash
# 원격 상태 저장소 사용 (S3 + DynamoDB)
terraform {
  backend "s3" {
    bucket = "tf-microservices-state"
    key    = "terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
}
```

### 2. 변수 보안
```hcl
# 민감한 정보는 변수로 관리
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# 또는 환경 변수 사용
variable "api_key" {
  description = "API Key"
  type        = string
  default     = ""
}

# terraform.tfvars 파일에서 설정
# api_key = "your-api-key"
```

### 3. IAM 권한 최소화
```hcl
# 최소 권한으로 IAM 역할 생성
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
```

## 📈 성능 최적화

### 1. 병렬 처리
```hcl
# 병렬로 생성할 수 있는 리소스들
resource "aws_subnet" "public" {
  count = 2
  
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

### 2. 조건부 리소스 생성
```hcl
# 환경에 따라 리소스 생성
resource "aws_autoscaling_group" "ecs_asg" {
  count = var.environment == "prod" ? 1 : 0
  
  name = "${var.project_name}-ecs-asg"
  # ... 기타 설정
}
```

### 3. 데이터 소스 활용
```hcl
# 기존 리소스 참조
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

## 📚 모듈화

### 1. 모듈 구조
```
modules/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ecs/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── alb/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### 2. 모듈 사용
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr = var.vpc_cidr
  environment = var.environment
}

module "ecs" {
  source = "./modules/ecs"
  
  cluster_name = "${var.project_name}-cluster"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.private_subnets
}
```

## 📚 추가 리소스

- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform 모듈 레지스트리](https://registry.terraform.io/)

## ⚠️ 주의사항

1. **비용 관리**: Terraform으로 생성된 리소스는 AWS 요금이 발생합니다
2. **상태 파일 관리**: 상태 파일을 안전하게 백업하고 관리하세요
3. **변수 관리**: 민감한 정보는 환경 변수나 암호화된 변수로 관리하세요
4. **테스트**: 프로덕션 배포 전에 개발/스테이징 환경에서 충분히 테스트하세요
5. **버전 관리**: Terraform 코드를 Git으로 버전 관리하세요

## 🆘 지원

문제가 발생하면:
1. 이 문서의 문제 해결 섹션 확인
2. Terraform 로그 확인 (`TF_LOG=DEBUG`)
3. Terraform 공식 문서 참조
4. HashiCorp Support 또는 커뮤니티 포럼 활용
