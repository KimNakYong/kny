# =============================================================================
# Team FOG - 완전한 인프라 통합 Terraform 파일
# 모든 리소스를 하나의 파일로 관리
# =============================================================================

# =============================================================================
# Terraform 및 Provider 설정
# =============================================================================

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
  region = var.aws_region
}

# =============================================================================
# 변수 정의
# =============================================================================

variable "aws_region" {
  type        = string
  default     = "ap-northeast-2"
  description = "AWS 리전"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "환경 (prod, dev, staging)"
}

variable "project_name" {
  type        = string
  default     = "fog"
  description = "프로젝트 이름"
}

variable "desired_count" {
  type        = number
  default     = 2
  description = "ECS 서비스 실행할 태스크 수"
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "CloudWatch 로그 보관 기간"
}

variable "awslogs_region" {
  type        = string
  default     = "ap-northeast-2"
  description = "CloudWatch 로그 리전"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "프라이빗 서브넷 ID 목록"
}

variable "service_security_group_id" {
  type        = string
  description = "ECS 서비스용 보안 그룹 ID"
}

variable "user_cpu" {
  type        = string
  default     = "512"
  description = "User Service CPU 할당량"
}

variable "user_memory" {
  type        = string
  default     = "1024"
  description = "User Service 메모리 할당량"
}

variable "booking_cpu" {
  type        = string
  default     = "512"
  description = "Booking Service CPU 할당량"
}

variable "booking_memory" {
  type        = string
  default     = "1024"
  description = "Booking Service 메모리 할당량"
}

variable "store_cpu" {
  type        = string
  default     = "512"
  description = "Store Service CPU 할당량"
}

variable "store_memory" {
  type        = string
  default     = "1024"
  description = "Store Service 메모리 할당량"
}

variable "user_image" {
  type        = string
  description = "User Service Docker 이미지"
}

variable "booking_image" {
  type        = string
  description = "Booking Service Docker 이미지"
}

variable "store_image" {
  type        = string
  description = "Store Service Docker 이미지"
}

variable "user_tg_arn" {
  type        = string
  description = "User Service ALB 타겟 그룹 ARN"
}

variable "booking_tg_arn" {
  type        = string
  description = "Booking Service ALB 타겟 그룹 ARN"
}

variable "store_tg_arn" {
  type        = string
  description = "Store Service ALB 타겟 그룹 ARN"
}

variable "booking_db_secret_arn" {
  type        = string
  description = "Booking Service DB Secret ARN"
}

variable "store_db_secret_arn" {
  type        = string
  description = "Store Service DB Secret ARN"
}

variable "user_db_secret_arn" {
  type        = string
  description = "User Service DB Secret ARN"
}

variable "cognito_user_pool_id" {
  type        = string
  default     = "ap-northeast-2_bdkXgjghs"
  description = "Cognito User Pool ID"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_id_2a" {
  type        = string
  description = "Public Subnet ID for AZ-2a (NAT Gateway)"
}

variable "public_subnet_id_2c" {
  type        = string
  description = "Public Subnet ID for AZ-2c (NAT Gateway)"
}

# =============================================================================
# NAT Gateway 설정 (Terraform으로 관리)
# =============================================================================

# NAT Gateway용 Elastic IP (AZ-2a)
resource "aws_eip" "nat_eip_2a" {
  domain = "vpc"

  tags = {
    Name        = "fog-nat-eip-2a"
    Environment = var.environment
  }
}

# NAT Gateway용 Elastic IP (AZ-2c)
resource "aws_eip" "nat_eip_2c" {
  domain = "vpc"

  tags = {
    Name        = "fog-nat-eip-2c"
    Environment = var.environment
  }
}

# NAT Gateway (AZ-2a)
resource "aws_nat_gateway" "fog_nat_2a" {
  allocation_id = aws_eip.nat_eip_2a.id
  subnet_id     = var.public_subnet_id_2a

  tags = {
    Name        = "NAT-2a"
    Environment = var.environment
  }

  # IGW는 data 소스로 참조하므로 명시적 종속성 제거
}

# NAT Gateway (AZ-2c)
resource "aws_nat_gateway" "fog_nat_2c" {
  allocation_id = aws_eip.nat_eip_2c.id
  subnet_id     = var.public_subnet_id_2c

  tags = {
    Name        = "NAT-2c"
    Environment = var.environment
  }

  # IGW는 data 소스로 참조하므로 명시적 종속성 제거
}

# Internet Gateway (기존 리소스 조회만)
data "aws_internet_gateway" "fog_igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# Private Subnet 라우팅 테이블 (AZ-2a) - 기존 리소스 import 필요
resource "aws_route_table" "private_rt_2a" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.fog_nat_2a.id
  }

  tags = {
    Name        = "fog-rtb-private-2a"
    Environment = var.environment
  }
}

# Private Subnet 라우팅 테이블 (AZ-2c) - 기존 리소스 import 필요
resource "aws_route_table" "private_rt_2c" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.fog_nat_2c.id
  }

  tags = {
    Name        = "fog-rtb-private-2c"
    Environment = var.environment
  }
}

# Private Subnet과 라우팅 테이블 연결 (AZ-2a) - 기존 리소스 import 필요
resource "aws_route_table_association" "private_rta_2a" {
  subnet_id      = var.private_subnet_ids[0]
  route_table_id = aws_route_table.private_rt_2a.id
}

# Private Subnet과 라우팅 테이블 연결 (AZ-2c) - 기존 리소스 import 필요
resource "aws_route_table_association" "private_rta_2c" {
  subnet_id      = var.private_subnet_ids[1]
  route_table_id = aws_route_table.private_rt_2c.id
}

# =============================================================================
# ECS 클러스터 및 서비스 설정
# =============================================================================

# ECS 클러스터 생성
resource "aws_ecs_cluster" "fog_cluster" {
  name = "${var.project_name}-cluster"

  # Container Insights 설정
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# =============================================================================
# CloudWatch 로그 그룹 설정
# =============================================================================

# User Service 로그 그룹
resource "aws_cloudwatch_log_group" "user_logs" {
  name              = "/ecs/user-service"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "user-service-logs"
    Environment = var.environment
  }
}

# Booking Service 로그 그룹
resource "aws_cloudwatch_log_group" "booking_logs" {
  name              = "/ecs/booking-service"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "booking-service-logs"
    Environment = var.environment
  }
}

# Store Service 로그 그룹
resource "aws_cloudwatch_log_group" "store_logs" {
  name              = "/ecs/store-service"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "store-service-logs"
    Environment = var.environment
  }
}

# =============================================================================
# IAM 역할 및 정책 설정
# =============================================================================

# ECS Task Role 생성
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

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

  tags = {
    Name        = "ecs-task-role"
    Environment = var.environment
  }
}

# 기존 ECS Execution Role 참조
data "aws_iam_role" "existing_ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

# ECS Task Execution Role에 ECR 권한 추가
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = data.aws_iam_role.existing_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role Policy 설정
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs-task-role-policy-team"
  role = aws_iam_role.ecs_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR 접근 권한
      {
        Sid    = "AllowECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      # CloudWatch 로그 권한
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      # SNS 발행 권한
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "*"
      },
      # Cognito 사용자 조회 권한
      {
        Sid    = "AllowCognitoAdminGetUser"
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminGetUser"
        ]
        Resource = "arn:aws:cognito-idp:${var.aws_region}:733995297457:userpool/${var.cognito_user_pool_id}"
      },
      # Cognito 사용자 삭제 권한
      {
        Sid    = "AllowCognitoAdminDeleteUser"
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminDeleteUser"
        ]
        Resource = "arn:aws:cognito-idp:${var.aws_region}:733995297457:userpool/${var.cognito_user_pool_id}"
      },
      # CloudFront 캐시 무효화 권한
      {
        Sid    = "AllowCloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = "arn:aws:cloudfront::733995297457:distribution/E3NPLCVDB66SWW"
      },
      # SQS 접근 권한
      {
        Sid    = "AllowSQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:CreateQueue",
          "sqs:DeleteQueue",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueues",
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:SetQueueAttributes"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# ECS 태스크 정의
# =============================================================================

# User Service 태스크 정의
resource "aws_ecs_task_definition" "user_task" {
  family                   = "user-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.user_cpu
  memory                   = var.user_memory
  execution_role_arn       = data.aws_iam_role.existing_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  # User Service용 쓰기 가능한 볼륨 정의
  volume {
    name = "writable-temp"
  }

  container_definitions = jsonencode([
    {
      name  = "user"
      image = var.user_image
      
      # 보안 강화: 비루트 사용자 설정
      user = "1001:1001"
      
      # 보안 강화: 읽기 전용 루트 파일시스템
      readonlyRootFilesystem = false
      
      # 보안 강화: 권한 상승 비활성화
      privileged = false

      # 쓰기 가능한 볼륨 마운트 (읽기 전용 파일시스템 대비)
      # mountPoints = []  # /app 디렉토리는 컨테이너 내부에서 처리

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "JAVA_TOOL_OPTIONS"
          value = "-XX:MaxRAMPercentage=75 -XX:+UseStringDeduplication -Djava.io.tmpdir=/app/tmp -Dserver.tomcat.basedir=/app/tomcat"
        },
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        },
        {
          name  = "COGNITO_LOGOUT_ENDPOINT"
          value = "https://ap-northeast-2bdkxgjghs.auth.ap-northeast-2.amazoncognito.com/logout"
        },
        {
          name  = "COGNITO_USER_POOL_ID"
          value = var.cognito_user_pool_id
        },
        {
          name  = "JWT_SECRET_KEY"
          value = "team-fog-jwt-secret-key-2025"
        },
        {
          name  = "COGNITO_JWKS_URL"
          value = "https://cognito-idp.ap-northeast-2.amazonaws.com/ap-northeast-2_bdkXgjghs/.well-known/jwks.json"
        },
        {
          name  = "COGNITO_AUTHORIZE_ENDPOINT"
          value = "https://ap-northeast-2bdkxgjghs.auth.ap-northeast-2.amazoncognito.com/oauth2/authorize"
        },
        {
          name  = "COGNITO_TOKEN_ENDPOINT"
          value = "https://ap-northeast-2bdkxgjghs.auth.ap-northeast-2.amazoncognito.com/oauth2/token"
        },
        {
          name  = "COGNITO_CLIENT_SECRET"
          value = "glbqfhe4mhsh1ikhi5tfe89aaiqrvihh75546p4lvhmt9qoutt1"
        },
        {
          name  = "COGNITO_DOMAIN"
          value = "ap-northeast-2bdkxgjghs.auth.ap-northeast-2.amazoncognito.com"
        },
        {
          name  = "COGNITO_REDIRECT_URI"
          value = "https://talkingpotato.shop/callback"
        },
        {
          name  = "COGNITO_CLIENT_ID"
          value = "k2q60p4rkctc3mpon0dui3v8h"
        },
        {
          name  = "SPRING_JPA_DATABASE_PLATFORM"
          value = "org.hibernate.dialect.OracleDialect"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${var.user_db_secret_arn}:host::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.user_db_secret_arn}:dbname::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.user_db_secret_arn}:password::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.user_db_secret_arn}:port::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.user_db_secret_arn}:username::"
        },
        {
          name      = "STDB_HOST"
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:733995297457:secret:fog/db/oracle/standby-O2H3zF:host::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/user-service"
          "awslogs-region"        = var.awslogs_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8080/health || exit 1"
        ]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = {
    Name        = "user-task"
    Environment = "production"
  }
}

# Booking Service 태스크 정의
resource "aws_ecs_task_definition" "booking_task" {
  family                   = "booking-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.booking_cpu
  memory                   = var.booking_memory
  execution_role_arn       = data.aws_iam_role.existing_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "booking"
      image = var.booking_image
      
      # 보안 강화: 비루트 사용자 설정
      user = "1001:1001"
      
      # 보안 강화: 읽기 전용 루트 파일시스템 (임시 해제)
      readonlyRootFilesystem = false
      
      # 보안 강화: 권한 상승 비활성화
      privileged = false

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "JAVA_TOOL_OPTIONS"
          value = "-XX:MaxRAMPercentage=75 -XX:+UseStringDeduplication -Djava.io.tmpdir=/app/tmp -Dserver.tomcat.basedir=/app/tomcat"
        },
        {
          name  = "COGNITO_USER_POOL_ID"
          value = var.cognito_user_pool_id
        },
        {
          name  = "SPRING_JPA_DATABASE_PLATFORM"
          value = "org.hibernate.dialect.OracleDialect"
        },
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${var.booking_db_secret_arn}:host::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.booking_db_secret_arn}:dbname::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.booking_db_secret_arn}:password::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.booking_db_secret_arn}:port::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.booking_db_secret_arn}:username::"
        },
        {
          name      = "STDB_HOST"
          valueFrom = "arn:aws:secretsmanager:ap-northeast-2:733995297457:secret:fog/db/oracle/standby-O2H3zF:host::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/booking-service"
          "awslogs-region"        = var.awslogs_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8080/health || exit 1"
        ]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = {
    Name        = "booking-task"
    Environment = "production"
  }
}

# Store Service 태스크 정의
resource "aws_ecs_task_definition" "store_task" {
  family                   = "store-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.store_cpu
  memory                   = var.store_memory
  execution_role_arn       = data.aws_iam_role.existing_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "store"
      image = var.store_image
      
      # 보안 강화: 비루트 사용자 설정
      user = "1001:1001"
      
      # 보안 강화: 읽기 전용 루트 파일시스템 (임시 해제)
      readonlyRootFilesystem = false
      
      # 보안 강화: 권한 상승 비활성화
      privileged = false

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "JAVA_TOOL_OPTIONS"
          value = "-XX:MaxRAMPercentage=75 -XX:+UseStringDeduplication -Djava.io.tmpdir=/app/tmp -Dserver.tomcat.basedir=/app/tomcat"
        },
        {
          name  = "COGNITO_ISSUER_URI"
          value = "https://cognito-idp.ap-northeast-2.amazonaws.com/ap-northeast-2_bdkXgjghs"
        },
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        },
        {
          name  = "S3_BUCKET_NAME"
          value = "fog-object"
        },
        {
          name  = "S3_IMAGE_PREFIX"
          value = "store/"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${var.store_db_secret_arn}:host::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.store_db_secret_arn}:dbname::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.store_db_secret_arn}:password::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.store_db_secret_arn}:port::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.store_db_secret_arn}:username::"
        },
        {
          name      = "STDB_HOST"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:733995297457:secret:fog/db/oracle/standby-O2H3zF:host::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/store-service"
          "awslogs-region"        = var.awslogs_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8080/health || exit 1"
        ]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = {
    Name        = "store-task"
    Environment = "production"
  }
}

# =============================================================================
# ECS 서비스 설정
# =============================================================================

# User Service
resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.fog_cluster.id
  task_definition = aws_ecs_task_definition.user_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  # ECS Exec 활성화
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.user_tg_arn
    container_name   = "user"
    container_port   = 8080
  }

  depends_on = [aws_ecs_task_definition.user_task]

  health_check_grace_period_seconds = 180

  tags = {
    Name        = "user-service"
    Environment = var.environment
  }
}

# Booking Service
resource "aws_ecs_service" "booking_service" {
  name            = "booking-service"
  cluster         = aws_ecs_cluster.fog_cluster.id
  task_definition = aws_ecs_task_definition.booking_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  # ECS Exec 활성화
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.booking_tg_arn
    container_name   = "booking"
    container_port   = 8080
  }

  depends_on = [aws_ecs_task_definition.booking_task]

  health_check_grace_period_seconds = 180

  tags = {
    Name        = "booking-service"
    Environment = var.environment
  }
}

# Store Service
resource "aws_ecs_service" "store_service" {
  name            = "store-service"
  cluster         = aws_ecs_cluster.fog_cluster.id
  task_definition = aws_ecs_task_definition.store_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  # ECS Exec 활성화
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.store_tg_arn
    container_name   = "store"
    container_port   = 8080
  }

  depends_on = [aws_ecs_task_definition.store_task]

  health_check_grace_period_seconds = 180

  tags = {
    Name        = "store-service"
    Environment = var.environment
  }
}

# =============================================================================
# ALB 리스너 규칙 설정 (기존 규칙들 복원)
# =============================================================================

# User Service 라우팅 규칙 (Priority: 1)
resource "aws_lb_listener_rule" "user_rule" {
  listener_arn = "arn:aws:elasticloadbalancing:ap-northeast-2:733995297457:listener/app/fog-alb/a70f8728bb734d27/59f053cfdd8923db"
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = var.user_tg_arn
  }

  condition {
    path_pattern {
      values = ["/api/users", "/api/users/*"]
    }
  }

  tags = {
    Name = "User Service Rule"
  }
}

# Store Service 라우팅 규칙 (Priority: 2)
resource "aws_lb_listener_rule" "store_rule" {
  listener_arn = "arn:aws:elasticloadbalancing:ap-northeast-2:733995297457:listener/app/fog-alb/a70f8728bb734d27/59f053cfdd8923db"
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = var.store_tg_arn
  }

  condition {
    path_pattern {
      values = ["/api/stores", "/api/stores/*"]
    }
  }

  tags = {
    Name = "Store Service Rule"
  }
}

# Booking Service 라우팅 규칙 (Priority: 3)
resource "aws_lb_listener_rule" "booking_rule" {
  listener_arn = "arn:aws:elasticloadbalancing:ap-northeast-2:733995297457:listener/app/fog-alb/a70f8728bb734d27/59f053cfdd8923db"
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = var.booking_tg_arn
  }

  condition {
    path_pattern {
      values = ["/api/bookings", "/api/bookings/*"]
    }
  }

  tags = {
    Name = "Booking Service Rule"
  }
}

# Favorites 라우팅 규칙 (Priority: 4) - Store Service로 라우팅
resource "aws_lb_listener_rule" "favorites_rule" {
  listener_arn = "arn:aws:elasticloadbalancing:ap-northeast-2:733995297457:listener/app/fog-alb/a70f8728bb734d27/59f053cfdd8923db"
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = var.store_tg_arn
  }

  condition {
    path_pattern {
      values = ["/api/favorites", "/api/favorites/*"]
    }
  }

  tags = {
    Name = "Favorites Rule"
  }
}

# Reviews 라우팅 규칙 (Priority: 5) - Store Service로 라우팅
resource "aws_lb_listener_rule" "reviews_rule" {
  listener_arn = "arn:aws:elasticloadbalancing:ap-northeast-2:733995297457:listener/app/fog-alb/a70f8728bb734d27/59f053cfdd8923db"
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = var.store_tg_arn
  }

  condition {
    path_pattern {
      values = ["/api/reviews", "/api/reviews/*"]
    }
  }

  tags = {
    Name = "Reviews Rule"
  }
}

# =============================================================================
# GitHub Actions IAM 정책
# =============================================================================

# GitHub Actions IAM 역할에 CloudFront 권한 추가
resource "aws_iam_policy" "GitHub_Actions_CloudFront_Policy" {
  name        = "GitHub_Actions_CloudFront_Policy"
  description = "CloudFront cache invalidation permissions for GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = "arn:aws:cloudfront::733995297457:distribution/E3NPLCVDB66SWW"
      }
    ]
  })
}

# GitHub Actions 역할에 CloudFront 정책 연결
resource "aws_iam_role_policy_attachment" "GitHub_Actions_CloudFront_Policy" {
  policy_arn = aws_iam_policy.GitHub_Actions_CloudFront_Policy.arn
  role       = "GitHub_Actions"
}

# =============================================================================
# 출력값 정의
# =============================================================================

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.fog_cluster.name
  description = "ECS 클러스터 이름"
}

output "ecs_cluster_id" {
  value       = aws_ecs_cluster.fog_cluster.id
  description = "ECS 클러스터 ID"
}

output "user_service_id" {
  value       = aws_ecs_service.user_service.id
  description = "User Service ID"
}

output "booking_service_id" {
  value       = aws_ecs_service.booking_service.id
  description = "Booking Service ID"
}

output "store_service_id" {
  value       = aws_ecs_service.store_service.id
  description = "Store Service ID"
}

output "ecs_task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ECS Task Role ARN"
}

output "ecs_execution_role_arn" {
  value       = data.aws_iam_role.existing_ecs_execution_role.arn
  description = "ECS Execution Role ARN"
}

output "user_task_definition_arn" {
  value       = aws_ecs_task_definition.user_task.arn
  description = "User Task Definition ARN"
}

output "booking_task_definition_arn" {
  value       = aws_ecs_task_definition.booking_task.arn
  description = "Booking Task Definition ARN"
}

output "store_task_definition_arn" {
  value       = aws_ecs_task_definition.store_task.arn
  description = "Store Task Definition ARN"
}

output "cloudwatch_log_groups" {
  value = {
    user_service    = aws_cloudwatch_log_group.user_logs.name
    booking_service = aws_cloudwatch_log_group.booking_logs.name
    store_service   = aws_cloudwatch_log_group.store_logs.name
  }
  description = "CloudWatch 로그 그룹 목록"
}

output "github_actions_policy_arn" {
  value       = aws_iam_policy.GitHub_Actions_CloudFront_Policy.arn
  description = "GitHub Actions CloudFront 정책 ARN"
}

output "nat_gateway_ids" {
  value = {
    nat_2a = aws_nat_gateway.fog_nat_2a.id
    nat_2c = aws_nat_gateway.fog_nat_2c.id
  }
  description = "NAT Gateway IDs"
}

output "nat_gateway_public_ips" {
  value = {
    nat_2a = aws_eip.nat_eip_2a.public_ip
    nat_2c = aws_eip.nat_eip_2c.public_ip
  }
  description = "NAT Gateway Public IPs"
}

output "internet_gateway_id" {
  value       = data.aws_internet_gateway.fog_igw.id
  description = "Internet Gateway ID"
}
