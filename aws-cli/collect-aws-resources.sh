#!/bin/bash

# AWS 리소스 정보 수집 스크립트
# 사용법: ./collect-aws-resources.sh

set -e

REGION="ap-northeast-2"
PROJECT_NAME="tf"
OUTPUT_DIR="aws-resources"

echo "🔍 AWS 리소스 정보 수집 시작..."

# 출력 디렉토리 생성
mkdir -p $OUTPUT_DIR

# 1. ECS Cluster 정보 수집
echo "📊 ECS Cluster 정보 수집 중..."
aws ecs describe-clusters \
    --clusters ${PROJECT_NAME}-microservices-cluster \
    --region $REGION \
    --query 'clusters[0]' \
    --output json > $OUTPUT_DIR/ecs-cluster.json

# 2. VPC 정보 수집
echo "🌐 VPC 정보 수집 중..."
aws ec2 describe-vpcs \
    --filters "Name=is-default,Values=true" \
    --region $REGION \
    --query 'Vpcs[0]' \
    --output json > $OUTPUT_DIR/vpc.json

# 3. ALB 정보 수집
echo "⚖️ ALB 정보 수집 중..."
aws elbv2 describe-load-balancers \
    --names ${PROJECT_NAME}-alb \
    --region $REGION \
    --query 'LoadBalancers[0]' \
    --output json > $OUTPUT_DIR/alb.json

# 4. ECR Repository 정보 수집
echo "📦 ECR Repository 정보 수집 중..."
aws ecr describe-repositories \
    --repository-names ${PROJECT_NAME}-user-service ${PROJECT_NAME}-store-service ${PROJECT_NAME}-booking-service \
    --region $REGION \
    --output json > $OUTPUT_DIR/ecr-repositories.json

# 5. Security Groups 정보 수집
echo "🔒 Security Groups 정보 수집 중..."
aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${PROJECT_NAME}-*" \
    --region $REGION \
    --output json > $OUTPUT_DIR/security-groups.json

# 6. Subnets 정보 수집
echo "🌐 Subnets 정보 수집 중..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $REGION)
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region $REGION \
    --output json > $OUTPUT_DIR/subnets.json

# 7. Target Groups 정보 수집
echo "🎯 Target Groups 정보 수집 중..."
aws elbv2 describe-target-groups \
    --region $REGION \
    --output json > $OUTPUT_DIR/target-groups.json

# 8. ECS Services 정보 수집
echo "🚀 ECS Services 정보 수집 중..."
aws ecs list-services \
    --cluster ${PROJECT_NAME}-microservices-cluster \
    --region $REGION \
    --output json > $OUTPUT_DIR/ecs-services-list.json

# 각 서비스의 상세 정보 수집
SERVICES=$(aws ecs list-services --cluster ${PROJECT_NAME}-microservices-cluster --region $REGION --query 'serviceArns' --output text)
for service in $SERVICES; do
    SERVICE_NAME=$(echo $service | cut -d'/' -f3)
    echo "  - $SERVICE_NAME 정보 수집 중..."
    aws ecs describe-services \
        --cluster ${PROJECT_NAME}-microservices-cluster \
        --services $SERVICE_NAME \
        --region $REGION \
        --output json > $OUTPUT_DIR/ecs-service-$SERVICE_NAME.json
done

# 9. Task Definitions 정보 수집
echo "📋 Task Definitions 정보 수집 중..."
aws ecs list-task-definitions \
    --family-prefix ${PROJECT_NAME} \
    --region $REGION \
    --output json > $OUTPUT_DIR/task-definitions-list.json

# 각 Task Definition의 상세 정보 수집
TASK_DEFINITIONS=$(aws ecs list-task-definitions --family-prefix ${PROJECT_NAME} --region $REGION --query 'taskDefinitionArns' --output text)
for taskDef in $TASK_DEFINITIONS; do
    TASK_DEF_NAME=$(echo $taskDef | cut -d'/' -f2)
    echo "  - $TASK_DEF_NAME 정보 수집 중..."
    aws ecs describe-task-definition \
        --task-definition $TASK_DEF_NAME \
        --region $REGION \
        --output json > $OUTPUT_DIR/task-definition-$TASK_DEF_NAME.json
done

# 10. CloudWatch Log Groups 정보 수집
echo "📊 CloudWatch Log Groups 정보 수집 중..."
aws logs describe-log-groups \
    --log-group-name-prefix "/ecs/${PROJECT_NAME}" \
    --region $REGION \
    --output json > $OUTPUT_DIR/log-groups.json

# 11. IAM Roles 정보 수집
echo "👤 IAM Roles 정보 수집 중..."
aws iam list-roles \
    --path-prefix "/aws-service-role/ecs" \
    --output json > $OUTPUT_DIR/iam-roles.json

# 12. 리소스 요약 정보 생성
echo "📝 리소스 요약 정보 생성 중..."
cat > $OUTPUT_DIR/summary.md << EOF
# AWS 리소스 요약

## 수집된 리소스들

### ECS Cluster
- Cluster Name: ${PROJECT_NAME}-microservices-cluster
- Region: $REGION

### Load Balancer
- ALB Name: ${PROJECT_NAME}-alb
- DNS Name: $(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --region $REGION --query 'LoadBalancers[0].DNSName' --output text)

### ECR Repositories
- ${PROJECT_NAME}-user-service
- ${PROJECT_NAME}-store-service
- ${PROJECT_NAME}-booking-service

### VPC
- VPC ID: $VPC_ID
- Type: Default VPC

### Services
$(aws ecs list-services --cluster ${PROJECT_NAME}-microservices-cluster --region $REGION --query 'serviceArns[]' --output text | tr '\t' '\n' | sed 's/.*\///')

## CDK Import 명령어

\`\`\`bash
# ECS Cluster Import
cdk import aws-ecs-cluster:${PROJECT_NAME}-microservices-cluster

# VPC Import
cdk import aws-ec2-vpc:$VPC_ID

# ALB Import
cdk import aws-elasticloadbalancingv2-loadbalancer:$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --region $REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# ECR Repositories Import
cdk import aws-ecr-repository:${PROJECT_NAME}-user-service
cdk import aws-ecr-repository:${PROJECT_NAME}-store-service
cdk import aws-ecr-repository:${PROJECT_NAME}-booking-service
\`\`\`

## CDK 코드 예시

\`\`\`typescript
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Construct } from 'constructs';

export class TFMicroservicesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // 기존 VPC 참조
    const vpc = ec2.Vpc.fromLookup(this, 'ExistingVPC', {
      vpcId: '$VPC_ID',
    });

    // 기존 ECS Cluster 참조
    const cluster = ecs.Cluster.fromClusterAttributes(this, 'ExistingCluster', {
      clusterName: '${PROJECT_NAME}-microservices-cluster',
      vpc: vpc,
    });

    // 기존 ALB 참조
    const alb = elbv2.ApplicationLoadBalancer.fromApplicationLoadBalancerAttributes(
      this, 'ExistingALB', {
        loadBalancerArn: '$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --region $REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text)',
        loadBalancerDnsName: '$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --region $REGION --query 'LoadBalancers[0].DNSName' --output text)',
      }
    );

    // 기존 ECR Repositories 참조
    const userRepo = ecr.Repository.fromRepositoryName(
      this, 'UserRepo', '${PROJECT_NAME}-user-service'
    );
    const storeRepo = ecr.Repository.fromRepositoryName(
      this, 'StoreRepo', '${PROJECT_NAME}-store-service'
    );
    const bookingRepo = ecr.Repository.fromRepositoryName(
      this, 'BookingRepo', '${PROJECT_NAME}-booking-service'
    );
  }
}
\`\`\`
EOF

echo "✅ 리소스 정보 수집 완료!"
echo "📁 수집된 정보: $OUTPUT_DIR/"
echo "📄 요약 정보: $OUTPUT_DIR/summary.md"
echo ""
echo "다음 단계:"
echo "1. $OUTPUT_DIR/summary.md 파일 확인"
echo "2. CDK 프로젝트 생성: cdk init app --language typescript"
echo "3. Import 명령어 실행"
echo "4. CDK 코드 작성 및 배포"
