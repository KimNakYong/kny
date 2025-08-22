#!/bin/bash

# AWS ECS 배포 스크립트
# 사용법: ./deploy-aws.sh

set -e

# 환경 변수 설정
REGION="ap-northeast-2"
CLUSTER_NAME="tf-microservices-cluster"
PROJECT_NAME="tf"

echo "🚀 AWS ECS 배포 시작..."

# 1. ECR Repository 생성
echo "📦 ECR Repository 생성 중..."
aws ecr create-repository --repository-name ${PROJECT_NAME}-user-service --region ${REGION} || echo "Repository already exists"
aws ecr create-repository --repository-name ${PROJECT_NAME}-store-service --region ${REGION} || echo "Repository already exists"
aws ecr create-repository --repository-name ${PROJECT_NAME}-booking-service --region ${REGION} || echo "Repository already exists"

# 2. ECS Cluster 생성
echo "🏗️ ECS Cluster 생성 중..."
aws ecs create-cluster \
    --cluster-name ${CLUSTER_NAME} \
    --region ${REGION} \
    --capacity-providers FARGATE \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 || echo "Cluster already exists"

# 3. Task Definition 생성
echo "📋 Task Definition 생성 중..."

# User Service Task Definition
cat > user-service-task-definition.json << EOF
{
  "family": "${PROJECT_NAME}-user-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "user-service",
      "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}-user-service:latest",
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
          "awslogs-group": "/ecs/${PROJECT_NAME}-user-service",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://user-service-task-definition.json --region ${REGION}

# Store Service Task Definition
cat > store-service-task-definition.json << EOF
{
  "family": "${PROJECT_NAME}-store-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "store-service",
      "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}-store-service:latest",
      "portMappings": [
        {
          "containerPort": 8081,
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
          "awslogs-group": "/ecs/${PROJECT_NAME}-store-service",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://store-service-task-definition.json --region ${REGION}

# Booking Service Task Definition
cat > booking-service-task-definition.json << EOF
{
  "family": "${PROJECT_NAME}-booking-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "booking-service",
      "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}-booking-service:latest",
      "portMappings": [
        {
          "containerPort": 8080,
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
          "awslogs-group": "/ecs/${PROJECT_NAME}-booking-service",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://booking-service-task-definition.json --region ${REGION}

# 4. CloudWatch Log Groups 생성
echo "📊 CloudWatch Log Groups 생성 중..."
aws logs create-log-group --log-group-name /ecs/${PROJECT_NAME}-user-service --region ${REGION} || echo "Log group already exists"
aws logs create-log-group --log-group-name /ecs/${PROJECT_NAME}-store-service --region ${REGION} || echo "Log group already exists"
aws logs create-log-group --log-group-name /ecs/${PROJECT_NAME}-booking-service --region ${REGION} || echo "Log group already exists"

# 5. Security Groups 생성
echo "🔒 Security Groups 생성 중..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${REGION})

# ALB Security Group
ALB_SG_ID=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-alb-sg \
    --description "Security group for ALB" \
    --vpc-id ${VPC_ID} \
    --region ${REGION} \
    --query 'GroupId' --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${PROJECT_NAME}-alb-sg" \
    --query 'SecurityGroups[0].GroupId' --output text --region ${REGION})

aws ec2 authorize-security-group-ingress \
    --group-id ${ALB_SG_ID} \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region ${REGION} 2>/dev/null || echo "Rule already exists"

# ECS Security Group
ECS_SG_ID=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-ecs-sg \
    --description "Security group for ECS tasks" \
    --vpc-id ${VPC_ID} \
    --region ${REGION} \
    --query 'GroupId' --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${PROJECT_NAME}-ecs-sg" \
    --query 'SecurityGroups[0].GroupId' --output text --region ${REGION})

aws ec2 authorize-security-group-ingress \
    --group-id ${ECS_SG_ID} \
    --protocol tcp \
    --port 8080-8085 \
    --source-group ${ALB_SG_ID} \
    --region ${REGION} 2>/dev/null || echo "Rule already exists"

# 6. Subnets 생성 (기본 VPC 사용)
echo "🌐 Subnets 설정 중..."
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[0:2].SubnetId' \
    --output text --region ${REGION})

SUBNET_1=$(echo ${SUBNET_IDS} | cut -d' ' -f1)
SUBNET_2=$(echo ${SUBNET_IDS} | cut -d' ' -f2)

# 7. Application Load Balancer 생성
echo "⚖️ Application Load Balancer 생성 중..."
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name ${PROJECT_NAME}-alb \
    --subnets ${SUBNET_1} ${SUBNET_2} \
    --security-groups ${ALB_SG_ID} \
    --region ${REGION} \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || \
    aws elbv2 describe-load-balancers \
    --names ${PROJECT_NAME}-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text --region ${REGION})

# 8. Target Groups 생성
echo "🎯 Target Groups 생성 중..."

# User Service Target Group
USER_TG_ARN=$(aws elbv2 create-target-group \
    --name ${PROJECT_NAME}-user-tg \
    --protocol HTTP \
    --port 8085 \
    --vpc-id ${VPC_ID} \
    --target-type ip \
    --health-check-path /actuator/health \
    --region ${REGION} \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || \
    aws elbv2 describe-target-groups \
    --names ${PROJECT_NAME}-user-tg \
    --query 'TargetGroups[0].TargetGroupArn' --output text --region ${REGION})

# Store Service Target Group
STORE_TG_ARN=$(aws elbv2 create-target-group \
    --name ${PROJECT_NAME}-store-tg \
    --protocol HTTP \
    --port 8081 \
    --vpc-id ${VPC_ID} \
    --target-type ip \
    --health-check-path /actuator/health \
    --region ${REGION} \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || \
    aws elbv2 describe-target-groups \
    --names ${PROJECT_NAME}-store-tg \
    --query 'TargetGroups[0].TargetGroupArn' --output text --region ${REGION})

# Booking Service Target Group
BOOKING_TG_ARN=$(aws elbv2 create-target-group \
    --name ${PROJECT_NAME}-booking-tg \
    --protocol HTTP \
    --port 8080 \
    --vpc-id ${VPC_ID} \
    --target-type ip \
    --health-check-path /actuator/health \
    --region ${REGION} \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || \
    aws elbv2 describe-target-groups \
    --names ${PROJECT_NAME}-booking-tg \
    --query 'TargetGroups[0].TargetGroupArn' --output text --region ${REGION})

# 9. ALB Listeners 생성
echo "🎧 ALB Listeners 생성 중..."

# User Service Listener
aws elbv2 create-listener \
    --load-balancer-arn ${ALB_ARN} \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=${USER_TG_ARN} \
    --region ${REGION} 2>/dev/null || echo "Listener already exists"

# 10. ECS Services 생성
echo "🚀 ECS Services 생성 중..."

# User Service
aws ecs create-service \
    --cluster ${CLUSTER_NAME} \
    --service-name ${PROJECT_NAME}-user-service \
    --task-definition ${PROJECT_NAME}-user-service \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_1},${SUBNET_2}],securityGroups=[${ECS_SG_ID}],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=${USER_TG_ARN},containerName=user-service,containerPort=8085" \
    --region ${REGION} 2>/dev/null || echo "Service already exists"

# Store Service
aws ecs create-service \
    --cluster ${CLUSTER_NAME} \
    --service-name ${PROJECT_NAME}-store-service \
    --task-definition ${PROJECT_NAME}-store-service \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_1},${SUBNET_2}],securityGroups=[${ECS_SG_ID}],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=${STORE_TG_ARN},containerName=store-service,containerPort=8081" \
    --region ${REGION} 2>/dev/null || echo "Service already exists"

# Booking Service
aws ecs create-service \
    --cluster ${CLUSTER_NAME} \
    --service-name ${PROJECT_NAME}-booking-service \
    --task-definition ${PROJECT_NAME}-booking-service \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_1},${SUBNET_2}],securityGroups=[${ECS_SG_ID}],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=${BOOKING_TG_ARN},containerName=booking-service,containerPort=8080" \
    --region ${REGION} 2>/dev/null || echo "Service already exists"

# 11. 정리
rm -f *-task-definition.json

echo "✅ 배포 완료!"
echo "🌐 ALB DNS: $(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].DNSName' --output text --region ${REGION})"
echo "📊 ECS Cluster: ${CLUSTER_NAME}"
echo "🔗 서비스 URL들:"
echo "   - User Service: http://$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].DNSName' --output text --region ${REGION})/api/users"
echo "   - Store Service: http://$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].DNSName' --output text --region ${REGION})/api/stores"
echo "   - Booking Service: http://$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].DNSName' --output text --region ${REGION})/api/bookings"
