<<<<<<< HEAD
# AWS 배포 방법 가이드

이 폴더에는 AWS ECS를 이용한 마이크로서비스 배포를 위한 다양한 방법들이 정리되어 있습니다.

## 📁 폴더 구조

```
deployment-guides/
├── README.md                    # 이 파일 (전체 개요)
├── aws-cdk/                     # AWS CDK를 사용한 배포
│   ├── README.md               # CDK 사용법
│   ├── cdk-import-guide.md     # 기존 리소스 Import 가이드
│   ├── aws-cdk-example.ts      # CDK 예제 코드
│   └── tf-cdk/                 # 실제 CDK 프로젝트
├── terraform/                   # Terraform을 사용한 배포
│   └── README.md               # Terraform 사용법
├── aws-cli/                     # AWS CLI를 사용한 배포
│   ├── README.md               # AWS CLI 사용법
│   ├── collect-aws-resources.sh # 리소스 정보 수집 스크립트
│   └── deploy-aws.sh           # 배포 스크립트
└── github-actions/              # GitHub Actions를 사용한 CI/CD
    ├── README.md               # GitHub Actions 사용법
    └── workflows/              # GitHub Actions 워크플로우
```

## 🚀 배포 방법별 비교

| 방법 | 장점 | 단점 | 추천도 | 복잡도 |
|------|------|------|--------|--------|
| **AWS CDK** | • TypeScript/JavaScript<br>• 타입 안전성<br>• AWS 서비스 완벽 통합<br>• 재사용 가능한 컴포넌트 | • 학습 곡선 있음<br>• Node.js 환경 필요 | ⭐⭐⭐⭐⭐ | 중간 |
| **Terraform** | • 멀티 클라우드 지원<br>• 강력한 상태 관리<br>• 풍부한 커뮤니티 | • HCL 문법 학습 필요<br>• AWS 전용 기능 제한 | ⭐⭐⭐⭐ | 중간 |
| **AWS CLI** | • 간단하고 직관적<br>• 빠른 구현<br>• AWS CLI만 있으면 됨 | • 오류 처리 복잡<br>• 상태 관리 어려움 | ⭐⭐⭐ | 낮음 |
| **GitHub Actions** | • CI/CD 통합<br>• 자동화된 배포<br>• 버전 관리 연동 | • GitHub 의존성<br>• 복잡한 설정 | ⭐⭐⭐⭐ | 높음 |

## 🎯 추천 워크플로우

### 1. **초기 테스트 단계** (AWS CLI)
- 빠르게 테스트하고 개념 확인
- `aws-cli/` 폴더의 스크립트 사용

### 2. **안정화 단계** (Terraform)
- 안정적인 인프라 관리
- `terraform/` 폴더의 설정 사용

### 3. **최종 운영 단계** (AWS CDK + GitHub Actions)
- 완전한 IaC 구현
- `aws-cdk/` + `github-actions/` 폴더 사용

## 📋 사전 준비사항

### 공통 요구사항
- AWS 계정 및 IAM 권한
- AWS CLI 설치 및 설정
- Docker 설치 (컨테이너 이미지 빌드용)

### 방법별 추가 요구사항
- **AWS CDK**: Node.js, TypeScript
- **Terraform**: Terraform CLI
- **GitHub Actions**: GitHub 저장소

## 🔧 빠른 시작

### 1. AWS CLI로 빠른 테스트
```bash
cd deployment-guides/aws-cli
# AWS CLI 설정 후
./deploy-aws.sh
```

### 2. CDK로 안정적인 배포
```bash
cd deployment-guides/aws-cdk/tf-cdk
npm install
cdk deploy
```

### 3. GitHub Actions로 자동화
```bash
# GitHub 저장소에 코드 푸시
git push origin main
# 자동으로 배포 실행
```

## 📚 상세 가이드

각 폴더의 README.md 파일에서 해당 방법의 상세한 사용법을 확인할 수 있습니다:

- [AWS CDK 가이드](./aws-cdk/README.md)
- [Terraform 가이드](./terraform/README.md)
- [AWS CLI 가이드](./aws-cli/README.md)
- [GitHub Actions 가이드](./github-actions/README.md)

## ⚠️ 주의사항

1. **프로덕션 환경**에서는 신중하게 진행
2. **비용 관리**에 주의 (AWS 리소스 사용료)
3. **보안 설정** 필수 (IAM, Security Groups)
4. **백업 및 복구** 전략 수립

## 🆘 문제 해결

각 방법별 문제 해결 가이드는 해당 폴더의 README.md 파일을 참조하세요.

## 📞 지원

문제가 발생하면 각 폴더의 문서를 먼저 확인하고, 추가 도움이 필요하면 문의해주세요.
=======
# asdf
>>>>>>> fd9f85c79b73127c08077ec829be251d85adc432
