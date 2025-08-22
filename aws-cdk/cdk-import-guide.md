# AWS CDK Import 가이드

## 1. CDK Import 사용법

### 1.1 CDK 프로젝트 초기화
```bash
# CDK 프로젝트 생성
mkdir tf-cdk-project
cd tf-cdk-project
cdk init app --language typescript

# CDK 설치
npm install aws-cdk-lib constructs
```

### 1.2 기존 리소스 Import
```bash
# ECS Cluster Import
cdk import aws-ecs-cluster:tf-microservices-cluster

# VPC Import (기본 VPC 사용 시)
cdk import aws-ec2-vpc:vpc-xxxxxxxxx

# ALB Import
cdk import aws-elasticloadbalancingv2-loadbalancer:arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/tf-alb/xxxxxxxxx

# ECR Repository Import
cdk import aws-ecr-repository:tf-user-service
cdk import aws-ecr-repository:tf-store-service
cdk import aws-ecr-repository:tf-booking-service
```

### 1.3 Import 후 코드 확인
```bash
# Import된 리소스 확인
cat cdk.out/imports.json

# CDK 코드 생성
cdk synth
```

## 2. 수동으로 리소스 정보 수집

### 2.1 AWS CLI로 리소스 정보 수집
```bash
# ECS Cluster 정보
aws ecs describe-clusters --clusters tf-microservices-cluster

# VPC 정보
aws ec2 describe-vpcs --filters "Name=is-default,Values=true"

# ALB 정보
aws elbv2 describe-load-balancers --names tf-alb

# ECR Repository 정보
aws ecr describe-repositories --repository-names tf-user-service tf-store-service tf-booking-service

# Security Groups 정보
aws ec2 describe-security-groups --filters "Name=group-name,Values=tf-*"

# Subnets 정보
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxxxxx"
```

### 2.2 수집된 정보로 CDK 코드 작성
```typescript
// lib/tf-microservices-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Construct } from 'constructs';

export class TFMicroservicesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // 기존 VPC 참조 (기본 VPC 사용 시)
    const vpc = ec2.Vpc.fromLookup(this, 'ExistingVPC', {
      isDefault: true,
    });

    // 기존 ECS Cluster 참조
    const cluster = ecs.Cluster.fromClusterAttributes(this, 'ExistingCluster', {
      clusterName: 'tf-microservices-cluster',
      vpc: vpc,
    });

    // 기존 ALB 참조
    const alb = elbv2.ApplicationLoadBalancer.fromApplicationLoadBalancerAttributes(
      this, 'ExistingALB', {
        loadBalancerArn: 'arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/tf-alb/xxxxxxxxx',
        loadBalancerDnsName: 'tf-alb-xxxxxxxxx.ap-northeast-2.elb.amazonaws.com',
        securityGroupId: 'sg-xxxxxxxxx',
      }
    );

    // 기존 ECR Repositories 참조
    const userRepo = ecr.Repository.fromRepositoryName(
      this, 'UserRepo', 'tf-user-service'
    );
    const storeRepo = ecr.Repository.fromRepositoryName(
      this, 'StoreRepo', 'tf-store-service'
    );
    const bookingRepo = ecr.Repository.fromRepositoryName(
      this, 'BookingRepo', 'tf-booking-service'
    );

    // 새로운 리소스 추가
    this.createService('user-service', 8085, cluster, alb, vpc, userRepo);
    this.createService('store-service', 8081, cluster, alb, vpc, storeRepo);
    this.createService('booking-service', 8080, cluster, alb, vpc, bookingRepo);
  }

  private createService(
    serviceName: string,
    port: number,
    cluster: ecs.ICluster,
    alb: elbv2.IApplicationLoadBalancer,
    vpc: ec2.IVpc,
    repository: ecr.IRepository
  ) {
    // Task Definition
    const taskDefinition = new ecs.FargateTaskDefinition(this, `${serviceName}-task`, {
      memoryLimitMiB: 512,
      cpu: 256,
    });

    const container = taskDefinition.addContainer(`${serviceName}-container`, {
      image: ecs.ContainerImage.fromEcrRepository(repository),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: serviceName,
      }),
      environment: {
        'SPRING_PROFILES_ACTIVE': 'prod',
      },
    });

    container.addPortMappings({
      containerPort: port,
      protocol: ecs.Protocol.TCP,
    });

    // Security Group
    const securityGroup = new ec2.SecurityGroup(this, `${serviceName}-sg`, {
      vpc,
      description: `Security group for ${serviceName}`,
      allowAllOutbound: true,
    });

    securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(port),
      `Allow ${serviceName} traffic`
    );

    // ECS Service
    const service = new ecs.FargateService(this, `${serviceName}-service`, {
      cluster,
      taskDefinition,
      serviceName: `tf-${serviceName}`,
      desiredCount: 2,
      securityGroups: [securityGroup],
      assignPublicIp: true,
    });

    // Target Group
    const targetGroup = new elbv2.ApplicationTargetGroup(this, `${serviceName}-tg`, {
      vpc,
      port: port,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        path: '/actuator/health',
        healthyHttpCodes: '200',
      },
    });

    // Listener Rule
    alb.addListener(`${serviceName}-listener`, {
      port: 80,
      defaultTargetGroups: [targetGroup],
    });

    // Auto Scaling
    const scaling = service.autoScaleTaskCount({
      maxCapacity: 5,
      minCapacity: 1,
    });

    scaling.scaleOnCpuUtilization(`${serviceName}-cpu-scaling`, {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.seconds(60),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });
  }
}
```

## 3. AWS CloudFormation 템플릿 활용

### 3.1 CloudFormation 템플릿 다운로드
```bash
# ALB CloudFormation 템플릿 다운로드
aws cloudformation get-template --stack-name tf-alb-stack > alb-template.yaml

# ECS CloudFormation 템플릿 다운로드
aws cloudformation get-template --stack-name tf-ecs-stack > ecs-template.yaml
```

### 3.2 CloudFormation 템플릿을 CDK로 변환
```bash
# cfn2ts 도구 사용 (CloudFormation to TypeScript)
npm install -g cfn2ts
cfn2ts alb-template.yaml > alb-cdk.ts
cfn2ts ecs-template.yaml > ecs-cdk.ts
```

## 4. AWS Config 활용

### 4.1 AWS Config로 리소스 정보 수집
```bash
# AWS Config 활성화
aws configservice start-configuration-recorder

# 리소스 정보 조회
aws configservice list-discovered-resources --resource-type AWS::ECS::Cluster
aws configservice list-discovered-resources --resource-type AWS::ElasticLoadBalancingV2::LoadBalancer
aws configservice list-discovered-resources --resource-type AWS::ECR::Repository
```

## 5. 실습 단계

### 5.1 현재 AWS 리소스 확인
```bash
# 1. 현재 리소스 목록 확인
aws ecs list-clusters
aws elbv2 describe-load-balancers
aws ecr describe-repositories

# 2. 리소스 상세 정보 수집
aws ecs describe-clusters --clusters tf-microservices-cluster --query 'clusters[0]'
aws elbv2 describe-load-balancers --names tf-alb --query 'LoadBalancers[0]'
```

### 5.2 CDK 프로젝트 생성
```bash
# 1. CDK 프로젝트 생성
mkdir tf-cdk
cd tf-cdk
cdk init app --language typescript

# 2. 의존성 설치
npm install aws-cdk-lib constructs

# 3. 환경 설정
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export CDK_DEFAULT_REGION=ap-northeast-2
```

### 5.3 Import 실행
```bash
# 1. Import 명령어 실행
cdk import aws-ecs-cluster:tf-microservices-cluster
cdk import aws-elasticloadbalancingv2-loadbalancer:arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/tf-alb/xxxxxxxxx

# 2. Import 결과 확인
cat cdk.out/imports.json
```

### 5.4 코드 생성 및 배포
```bash
# 1. CDK 코드 생성
cdk synth

# 2. 배포 계획 확인
cdk diff

# 3. 배포 실행
cdk deploy
```

## 6. 주의사항

### 6.1 Import 제한사항
- 모든 리소스가 Import 가능하지 않음
- 일부 리소스는 수동으로 코드 작성 필요
- Import 후 리소스 수정 시 주의 필요

### 6.2 권장사항
- Import 전 백업 생성
- 단계별로 Import 진행
- Import 후 테스트 필수
- 프로덕션 환경에서는 신중하게 진행
