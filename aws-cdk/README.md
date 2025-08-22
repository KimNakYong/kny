# AWS CDK 배포 가이드

AWS CDK(Cloud Development Kit)를 사용하여 마이크로서비스를 AWS ECS에 배포하는 방법입니다.

## 📋 사전 준비사항

### 1. 필수 도구 설치
```bash
# Node.js 설치 (v18 이상)
# https://nodejs.org/

# AWS CDK CLI 설치
npm install -g aws-cdk

# AWS CLI 설치 및 설정
# https://aws.amazon.com/cli/
aws configure
```

### 2. AWS 권한 확인
- ECS Full Access
- EC2 Full Access
- ECR Full Access
- IAM Full Access
- CloudWatch Full Access

## 🚀 빠른 시작

### 1. CDK 프로젝트 생성
```bash
cd deployment-guides/aws-cdk
mkdir my-cdk-project
cd my-cdk-project
cdk init app --language typescript
```

### 2. 의존성 설치
```bash
npm install aws-cdk-lib constructs
```

### 3. 환경 설정
```bash
# AWS 계정 및 리전 설정
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export CDK_DEFAULT_REGION=ap-northeast-2
```

### 4. 배포 실행
```bash
# CDK 코드 생성
cdk synth

# 배포 계획 확인
cdk diff

# 배포 실행
cdk deploy
```

## 📁 프로젝트 구조

```
aws-cdk/
├── README.md                    # 이 파일
├── cdk-import-guide.md          # 기존 리소스 Import 가이드
├── aws-cdk-example.ts           # CDK 예제 코드
└── tf-cdk/                      # 실제 CDK 프로젝트
    ├── package.json
    ├── bin/
    │   └── tf-cdk.ts           # CDK 앱 진입점
    └── lib/
        └── tf-microservices-stack.ts  # 메인 스택
```

## 🔧 기존 AWS 리소스 Import

### 1. 리소스 정보 수집
```bash
# ECS Cluster 정보
aws ecs describe-clusters --clusters tf-microservices-cluster

# ALB 정보
aws elbv2 describe-load-balancers --names tf-alb

# ECR Repository 정보
aws ecr describe-repositories --repository-names tf-user-service
```

### 2. Import 실행
```bash
# ECS Cluster Import
cdk import aws-ecs-cluster:tf-microservices-cluster

# ALB Import
cdk import aws-elasticloadbalancingv2-loadbalancer:arn:aws:elasticloadbalancing:...

# ECR Repository Import
cdk import aws-ecr-repository:tf-user-service
```

### 3. Import 결과 확인
```bash
# Import된 리소스 확인
cat cdk.out/imports.json

# CDK 코드 생성
cdk synth
```

## 📝 CDK 코드 작성

### 기본 스택 구조
```typescript
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Construct } from 'constructs';

export class TFMicroservicesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // VPC 생성
    const vpc = new ec2.Vpc(this, 'TFVPC', {
      maxAzs: 2,
      natGateways: 1,
    });

    // ECS Cluster 생성
    const cluster = new ecs.Cluster(this, 'TFCluster', {
      vpc,
      clusterName: 'tf-microservices-cluster',
    });

    // 서비스 생성
    this.createService('user-service', 8085, cluster, vpc);
    this.createService('store-service', 8081, cluster, vpc);
    this.createService('booking-service', 8080, cluster, vpc);
  }

  private createService(serviceName: string, port: number, cluster: ecs.Cluster, vpc: ec2.Vpc) {
    // 서비스별 리소스 생성 로직
  }
}
```

### 기존 리소스 참조
```typescript
// 기존 VPC 참조
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
    loadBalancerArn: 'arn:aws:elasticloadbalancing:...',
    loadBalancerDnsName: 'tf-alb-xxx.ap-northeast-2.elb.amazonaws.com',
  }
);
```

## 🔄 배포 및 업데이트

### 1. 초기 배포
```bash
cdk deploy
```

### 2. 업데이트 배포
```bash
# 코드 수정 후
cdk diff    # 변경사항 확인
cdk deploy  # 배포
```

### 3. 특정 스택만 배포
```bash
cdk deploy TFMicroservicesStack
```

### 4. 배포 롤백
```bash
# 이전 버전으로 롤백
cdk rollback
```

## 📊 모니터링 및 로그

### 1. CloudWatch 로그 확인
```bash
# 로그 그룹 확인
aws logs describe-log-groups --log-group-name-prefix "/ecs/tf-"

# 로그 스트림 확인
aws logs describe-log-streams --log-group-name "/ecs/tf-user-service"

# 로그 조회
aws logs get-log-events --log-group-name "/ecs/tf-user-service" --log-stream-name "ecs/user-service/..."
```

### 2. ECS 서비스 상태 확인
```bash
# 서비스 목록
aws ecs list-services --cluster tf-microservices-cluster

# 서비스 상세 정보
aws ecs describe-services --cluster tf-microservices-cluster --services tf-user-service
```

## 🛠️ 문제 해결

### 1. 일반적인 오류

#### CDK Bootstrap 오류
```bash
# CDK Bootstrap 실행
cdk bootstrap aws://ACCOUNT-NUMBER/REGION
```

#### 권한 오류
```bash
# IAM 권한 확인
aws sts get-caller-identity

# 필요한 정책 추가
aws iam attach-user-policy --user-name YOUR_USER --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### VPC Lookup 오류
```bash
# VPC ID 직접 지정
const vpc = ec2.Vpc.fromLookup(this, 'ExistingVPC', {
  vpcId: 'vpc-xxxxxxxxx',
});
```

### 2. 디버깅

#### CDK 디버그 모드
```bash
cdk deploy --debug
```

#### CloudFormation 템플릿 확인
```bash
cdk synth --json > template.json
```

#### 리소스 상태 확인
```bash
aws cloudformation describe-stacks --stack-name TFMicroservicesStack
```

## 📚 추가 리소스

- [AWS CDK 공식 문서](https://docs.aws.amazon.com/cdk/)
- [CDK API 참조](https://docs.aws.amazon.com/cdk/api/v2/)
- [CDK 예제](https://github.com/aws-samples/aws-cdk-examples)

## ⚠️ 주의사항

1. **비용 관리**: CDK로 생성된 리소스는 AWS 요금이 발생합니다
2. **보안**: 프로덕션 환경에서는 적절한 IAM 권한 설정이 필요합니다
3. **백업**: 중요한 데이터는 별도 백업 전략을 수립하세요
4. **테스트**: 프로덕션 배포 전에 개발/스테이징 환경에서 충분히 테스트하세요

## 🆘 지원

문제가 발생하면:
1. 이 문서의 문제 해결 섹션 확인
2. AWS CDK 공식 문서 참조
3. AWS Support 또는 커뮤니티 포럼 활용
