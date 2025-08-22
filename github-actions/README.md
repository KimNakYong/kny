# GitHub Actions CI/CD 가이드

GitHub Actions를 사용하여 마이크로서비스를 AWS ECS에 자동으로 배포하는 방법입니다.

## 📋 사전 준비사항

### 1. GitHub 저장소 설정
- GitHub 저장소 생성
- 코드를 저장소에 푸시
- GitHub Secrets 설정

### 2. AWS 설정
- AWS IAM 사용자 생성 (프로그래밍 방식 액세스)
- 필요한 권한 부여
- Access Key 및 Secret Key 생성

### 3. GitHub Secrets 설정
GitHub 저장소의 Settings > Secrets and variables > Actions에서 다음 시크릿을 설정:

```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
CLOUDFRONT_DISTRIBUTION_ID=your_cloudfront_distribution_id
CLOUDFRONT_DOMAIN=your_cloudfront_domain
```

## 🚀 빠른 시작

### 1. 워크플로우 파일 추가
```bash
# .github/workflows/deploy.yml 파일을 저장소에 추가
```

### 2. 코드 푸시
```bash
git add .
git commit -m "Add GitHub Actions workflow"
git push origin main
```

### 3. 배포 확인
- GitHub 저장소의 Actions 탭에서 워크플로우 실행 상태 확인
- AWS ECS 콘솔에서 서비스 배포 상태 확인

## 📁 파일 구조

```
.github/
└── workflows/
    └── deploy.yml              # GitHub Actions 워크플로우
```

## 🔧 워크플로우 상세 설명

### 1. 트리거 설정
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
```

### 2. 환경 변수 설정
```yaml
env:
  AWS_REGION: ap-northeast-2
  ECR_REPOSITORY_USER: tf-user-service
  ECR_REPOSITORY_STORE: tf-store-service
  ECR_REPOSITORY_BOOKING: tf-booking-service
  ECS_CLUSTER: tf-microservices-cluster
  ECS_SERVICE_USER: tf-user-service
  ECS_SERVICE_STORE: tf-store-service
  ECS_SERVICE_BOOKING: tf-booking-service
```

### 3. 빌드 및 배포 단계

#### AWS 자격 증명 설정
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
```

#### ECR 로그인
```yaml
- name: Login to Amazon ECR
  id: login-ecr
  uses: aws-actions/amazon-ecr-login@v2
```

#### Java 및 Node.js 설정
```yaml
- name: Set up JDK 17
  uses: actions/setup-java@v4
  with:
    java-version: '17'
    distribution: 'temurin'

- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'
```

#### Docker 이미지 빌드 및 푸시
```yaml
- name: Build User Service Docker image
  working-directory: ./TF-user-service
  run: |
    docker build -t ${{ env.ECR_REPOSITORY_USER }}:${{ github.sha }} .
    docker tag ${{ env.ECR_REPOSITORY_USER }}:${{ github.sha }} ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY_USER }}:${{ github.sha }}
    docker tag ${{ env.ECR_REPOSITORY_USER }}:${{ github.sha }} ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY_USER }}:latest

- name: Push User Service to ECR
  run: |
    docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY_USER }}:${{ github.sha }}
    docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY_USER }}:latest
```

#### ECS 서비스 업데이트
```yaml
- name: Update User Service ECS service
  run: |
    aws ecs update-service --cluster ${{ env.ECS_CLUSTER }} --service ${{ env.ECS_SERVICE_USER }} --force-new-deployment
```

## 📊 모니터링 및 알림

### 1. 워크플로우 상태 확인
- GitHub 저장소의 Actions 탭에서 실시간 상태 확인
- 각 단계별 로그 확인 가능

### 2. 배포 알림 설정
```yaml
- name: Notify deployment success
  run: |
    echo "✅ 배포 완료!"
    echo "🌐 ALB DNS: ${{ steps.alb-dns.outputs.alb-dns }}"
    echo "🔗 서비스 URL들:"
    echo "   - User Service: http://${{ steps.alb-dns.outputs.alb-dns }}/api/users"
    echo "   - Store Service: http://${{ steps.alb-dns.outputs.alb-dns }}/api/stores"
    echo "   - Booking Service: http://${{ steps.alb-dns.outputs.alb-dns }}/api/bookings"
    echo "   - Frontend: https://${{ secrets.CLOUDFRONT_DOMAIN }}"
```

### 3. Slack/Discord 알림 추가
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    channel: '#deployments'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

## 🔄 배포 전략

### 1. Blue-Green 배포
```yaml
- name: Blue-Green Deployment
  run: |
    # Blue 환경 배포
    aws ecs update-service --cluster ${{ env.ECS_CLUSTER }} --service ${{ env.ECS_SERVICE_USER }}-blue --force-new-deployment
    
    # 헬스 체크 대기
    aws ecs wait services-stable --cluster ${{ env.ECS_CLUSTER }} --services ${{ env.ECS_SERVICE_USER }}-blue
    
    # Green 환경으로 트래픽 전환
    aws elbv2 modify-listener --listener-arn ${{ env.LISTENER_ARN }} --default-actions Type=forward,TargetGroupArn=${{ env.GREEN_TARGET_GROUP_ARN }}
```

### 2. Rolling 배포
```yaml
- name: Rolling Deployment
  run: |
    # 서비스 업데이트 (기본적으로 Rolling 배포)
    aws ecs update-service --cluster ${{ env.ECS_CLUSTER }} --service ${{ env.ECS_SERVICE_USER }} --force-new-deployment
    
    # 배포 완료 대기
    aws ecs wait services-stable --cluster ${{ env.ECS_CLUSTER }} --services ${{ env.ECS_SERVICE_USER }}
```

### 3. Canary 배포
```yaml
- name: Canary Deployment
  run: |
    # Canary 서비스 배포 (10% 트래픽)
    aws ecs update-service --cluster ${{ env.ECS_CLUSTER }} --service ${{ env.ECS_SERVICE_USER }}-canary --desired-count 1
    
    # 모니터링 대기
    sleep 300
    
    # 성공 시 전체 배포
    aws ecs update-service --cluster ${{ env.ECS_CLUSTER }} --service ${{ env.ECS_SERVICE_USER }} --force-new-deployment
```

## 🛠️ 문제 해결

### 1. 일반적인 오류

#### 권한 오류
```bash
# IAM 정책 확인
aws iam get-user-policy --user-name YOUR_USER --policy-name YOUR_POLICY

# 필요한 정책 추가
aws iam attach-user-policy --user-name YOUR_USER --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### ECR 푸시 오류
```bash
# ECR Repository 존재 확인
aws ecr describe-repositories --repository-names tf-user-service

# Repository가 없으면 생성
aws ecr create-repository --repository-name tf-user-service
```

#### ECS 서비스 업데이트 오류
```bash
# 서비스 상태 확인
aws ecs describe-services --cluster tf-microservices-cluster --services tf-user-service

# Task Definition 확인
aws ecs describe-task-definition --task-definition tf-user-service
```

### 2. 디버깅

#### 워크플로우 로그 확인
- GitHub Actions 탭에서 실패한 워크플로우 클릭
- 실패한 단계의 로그 확인

#### AWS 리소스 상태 확인
```bash
# ECS 서비스 상태
aws ecs describe-services --cluster tf-microservices-cluster --services tf-user-service

# ECR 이미지 확인
aws ecr describe-images --repository-name tf-user-service

# ALB 상태 확인
aws elbv2 describe-load-balancers --names tf-alb
```

## 🔒 보안 고려사항

### 1. IAM 권한 최소화
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. GitHub Secrets 관리
- 정기적인 Access Key 로테이션
- 최소 권한 원칙 적용
- Secrets 접근 로그 모니터링

### 3. 네트워크 보안
- VPC 내부에서만 통신하도록 설정
- Security Groups 최소 권한 설정
- HTTPS 통신 강제

## 📈 성능 최적화

### 1. 빌드 캐시 활용
```yaml
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-
```

### 2. 병렬 빌드
```yaml
jobs:
  build-user-service:
    runs-on: ubuntu-latest
    steps:
      # User Service 빌드

  build-store-service:
    runs-on: ubuntu-latest
    steps:
      # Store Service 빌드

  build-booking-service:
    runs-on: ubuntu-latest
    steps:
      # Booking Service 빌드

  deploy:
    needs: [build-user-service, build-store-service, build-booking-service]
    runs-on: ubuntu-latest
    steps:
      # 배포
```

### 3. 조건부 배포
```yaml
- name: Deploy to Production
  if: github.ref == 'refs/heads/main'
  run: |
    # 프로덕션 배포

- name: Deploy to Staging
  if: github.ref == 'refs/heads/develop'
  run: |
    # 스테이징 배포
```

## 📚 추가 리소스

- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)
- [AWS ECS GitHub Actions](https://github.com/aws-actions/amazon-ecs-deploy-task-definition)
- [Docker GitHub Actions](https://github.com/docker/build-push-action)

## ⚠️ 주의사항

1. **비용 관리**: GitHub Actions 실행 시간과 AWS 리소스 사용료 발생
2. **보안**: GitHub Secrets와 AWS IAM 권한 관리 주의
3. **모니터링**: 배포 후 서비스 상태 확인 필수
4. **롤백**: 문제 발생 시 빠른 롤백 전략 수립
5. **테스트**: 프로덕션 배포 전 충분한 테스트 수행

## 🆘 지원

문제가 발생하면:
1. GitHub Actions 로그 확인
2. AWS CloudWatch 로그 확인
3. GitHub Support 또는 AWS Support 활용
