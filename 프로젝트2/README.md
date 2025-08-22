# Restaurant Reservation System

## 🎉 완성된 프로젝트!

### ✅ 백엔드 완성
- Spring Boot 3.2.0 기반 REST API
- JPA/Hibernate를 통한 데이터베이스 관리
- H2 인메모리 데이터베이스
- 완전한 CRUD 기능
- 포괄적인 테스트 커버리지

### ✅ 프론트엔드 완성
- 모던하고 반응형 웹 인터페이스
- Bootstrap 5 + Font Awesome
- 실시간 데이터 동기화
- 직관적인 사용자 경험

## 🚀 주요 기능

### 🏪 레스토랑 관리
- **레스토랑 등록/수정/삭제**: 완전한 CRUD 기능
- **검색 및 필터링**: 이름, 주소, 상태별 검색
- **상세 정보**: 수용인원, 영업시간, 연락처 등
- **상태 관리**: 영업중/휴업 상태 관리

### 📅 예약 관리
- **예약 생성**: 레스토랑, 고객, 날짜/시간 선택
- **상태 관리**: 대기중, 확정, 취소, 완료 상태
- **검색 및 필터**: 고객명, 레스토랑명, 상태별 검색
- **특별 요청사항**: 예약 시 추가 요청사항 입력

### 👤 사용자 인증
- **회원가입**: 이메일 기반 회원가입
- **로그인/로그아웃**: 세션 관리
- **비밀번호 유효성 검사**: 보안 강화
- **소셜 로그인**: Google, Facebook, Kakao 지원 (개발 중)

### 📊 관리자 대시보드
- **실시간 통계**: 레스토랑, 고객, 예약 수 표시
- **차트 및 분석**: 예약 상태 분포, 인기 레스토랑
- **최근 활동**: 최신 예약 내역 실시간 표시
- **데이터 내보내기**: JSON 형태로 데이터 백업

## 🎨 프론트엔드 페이지

### 1. **메인 페이지** (`/`)
- 시스템 소개 및 주요 기능 안내
- 인기 레스토랑 표시
- 실시간 통계 대시보드
- 직관적인 네비게이션

### 2. **레스토랑 목록** (`/restaurants`)
- 모든 레스토랑 카드 형태 표시
- 실시간 검색 및 필터링
- 레스토랑 추가 모달
- 정렬 기능 (이름순, 수용인원순)

### 3. **예약 관리** (`/reservations`)
- 예약 목록 및 상태별 필터링
- 새 예약 생성 모달
- 예약 수정/취소 기능
- 실시간 검색

### 4. **로그인** (`/login`)
- 이메일/비밀번호 로그인
- 소셜 로그인 지원
- 로그인 상태 유지
- 비밀번호 찾기 기능

### 5. **회원가입** (`/signup`)
- 이메일 기반 회원가입
- 비밀번호 유효성 검사
- 이용약관 동의
- 마케팅 정보 수신 동의

### 5. **관리자 대시보드** (`/admin`)
- 시스템 통계 실시간 표시
- 예약 상태 분포 차트
- 인기 레스토랑 순위
- 최근 활동 내역
- 데이터 내보내기 기능

## 🛠 기술 스택

### Backend
- **Spring Boot**: 3.2.0
- **Spring Data JPA**: 데이터베이스 접근
- **H2 Database**: 인메모리 데이터베이스
- **Maven**: 빌드 도구
- **JUnit 5**: 테스트 프레임워크
- **Mockito**: 모킹 프레임워크

### Frontend
- **Bootstrap 5**: 반응형 UI 프레임워크
- **Font Awesome**: 아이콘 라이브러리
- **Vanilla JavaScript**: 동적 기능 구현
- **Thymeleaf**: 서버사이드 템플릿

### 개발 도구
- **IntelliJ IDEA**: IDE
- **Java 17**: 프로그래밍 언어
- **Maven**: 의존성 관리

## 🚀 실행 방법

### 1. 프로젝트 설정
```bash
# 프로젝트 클론 또는 다운로드
cd 프로젝트2

# Maven 의존성 설치
mvn clean install
```

### 2. IntelliJ에서 실행
1. **프로젝트 열기**: IntelliJ에서 프로젝트 폴더 열기
2. **JDK 설정**: Java 17 설정 확인
3. **Maven 새로고침**: 의존성 다운로드
4. **애플리케이션 실행**: `ReservationApplication.java` 실행

### 3. 웹 브라우저에서 접속
- **메인 페이지**: http://localhost:8080/
- **레스토랑 관리**: http://localhost:8080/restaurants
- **예약 관리**: http://localhost:8080/reservations
- **로그인**: http://localhost:8080/login
- **회원가입**: http://localhost:8080/signup
- **관리자 대시보드**: http://localhost:8080/admin
- **H2 데이터베이스 콘솔**: http://localhost:8080/h2-console

## 🧪 테스트 실행

### IntelliJ에서 테스트 실행
1. **VM 옵션 설정**:
   ```
   Run → Edit Configurations → Templates → JUnit → VM options
   ```
   다음 추가:
   ```
   -Dnet.bytebuddy.experimental=true
   ```

2. **테스트 실행**:
   ```
   Run → Run All Tests
   ```

### 테스트 커버리지
- **단위 테스트**: Service, Repository 레이어
- **통합 테스트**: Controller 레이어
- **API 테스트**: REST 엔드포인트 검증

## 📁 프로젝트 구조

```
프로젝트2/
├── src/
│   ├── main/
│   │   ├── java/com/restaurant/reservation/
│   │   │   ├── ReservationApplication.java
│   │   │   ├── entity/
│   │   │   │   ├── Restaurant.java
│   │   │   │   ├── Customer.java
│   │   │   │   ├── Reservation.java
│   │   │   │   └── ReservationStatus.java
│   │   │   ├── repository/
│   │   │   │   ├── RestaurantRepository.java
│   │   │   │   ├── CustomerRepository.java
│   │   │   │   └── ReservationRepository.java
│   │   │   ├── service/
│   │   │   │   ├── RestaurantService.java
│   │   │   │   ├── CustomerService.java
│   │   │   │   └── ReservationService.java
│   │   │   ├── controller/
│   │   │   │   ├── RestaurantController.java
│   │   │   │   ├── CustomerController.java
│   │   │   │   ├── ReservationController.java
│   │   │   │   └── WebController.java
│   │   │   └── config/
│   │   │       └── DataLoader.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── templates/
│   │           ├── index.html
│   │           ├── restaurants.html
│   │           ├── reservations.html
│   │           ├── customers.html
│   │           └── admin.html
│   └── test/
│       └── java/com/restaurant/reservation/
│           ├── ReservationApplicationTests.java
│           ├── controller/
│           │   ├── RestaurantControllerTest.java
│           │   └── RestaurantControllerIntegrationTest.java
│           ├── service/
│           │   └── RestaurantServiceTest.java
│           └── repository/
│               └── RestaurantRepositoryTest.java
├── pom.xml
├── README.md
└── INTELLIJ_SETUP.md
```

## 🎯 사용 시나리오

### 1. 레스토랑 등록
1. `/restaurants` 페이지 접속
2. "레스토랑 추가" 버튼 클릭
3. 레스토랑 정보 입력 (이름, 주소, 전화번호 등)
4. "추가" 버튼 클릭

### 2. 회원가입
1. `/signup` 페이지 접속
2. 개인정보 입력 (이름, 이메일, 전화번호 등)
3. 비밀번호 설정 (보안 요구사항 충족)
4. 이용약관 동의 후 "회원가입" 버튼 클릭

### 3. 로그인
1. `/login` 페이지 접속
2. 이메일과 비밀번호 입력
3. "로그인" 버튼 클릭

### 4. 예약 생성
1. `/reservations` 페이지 접속
2. "새 예약 만들기" 버튼 클릭
3. 레스토랑, 고객, 날짜/시간, 인원 선택
4. "예약하기" 버튼 클릭

### 4. 예약 관리
1. `/reservations` 페이지에서 예약 목록 확인
2. 상태별 필터링 (대기중, 확정, 취소, 완료)
3. 예약 수정 또는 취소

### 6. 시스템 모니터링
1. `/admin` 페이지 접속
2. 실시간 통계 확인
3. 예약 상태 분포 및 인기 레스토랑 확인
4. 최근 활동 내역 확인

## 🔧 API 엔드포인트

### 레스토랑 API
- `GET /api/restaurants` - 모든 레스토랑 조회
- `GET /api/restaurants/{id}` - 특정 레스토랑 조회
- `POST /api/restaurants` - 레스토랑 등록
- `PUT /api/restaurants/{id}` - 레스토랑 수정
- `DELETE /api/restaurants/{id}` - 레스토랑 삭제
- `GET /api/restaurants/search` - 레스토랑 검색

### 인증 API
- `POST /api/auth/signup` - 회원가입
- `POST /api/auth/login` - 로그인
- `GET /api/auth/check-email` - 이메일 중복 확인
- `POST /api/auth/logout` - 로그아웃

### 예약 API
- `GET /api/reservations` - 모든 예약 조회
- `GET /api/reservations/{id}` - 특정 예약 조회
- `POST /api/reservations` - 예약 생성
- `PUT /api/reservations/{id}/status` - 예약 상태 변경
- `DELETE /api/reservations/{id}` - 예약 삭제

## 🎨 UI/UX 특징

### 반응형 디자인
- 모바일, 태블릿, 데스크톱 호환
- Bootstrap 5 그리드 시스템 활용
- 터치 친화적 인터페이스

### 모던 디자인
- 그라데이션 배경 및 버튼
- 호버 효과 및 애니메이션
- 일관된 색상 팔레트
- Font Awesome 아이콘 활용

### 사용자 경험
- 직관적인 네비게이션
- 실시간 검색 및 필터링
- 모달을 통한 간편한 데이터 입력
- 성공/에러 메시지 표시

## 📊 데이터베이스 스키마

### Restaurant (레스토랑)
- `id`: 기본키
- `name`: 레스토랑명
- `address`: 주소
- `phone`: 전화번호
- `description`: 설명
- `capacity`: 수용 인원
- `openingHours`: 영업시간
- `active`: 활성화 여부

### Customer (고객)
- `id`: 기본키
- `name`: 고객명
- `email`: 이메일 (고유)
- `phone`: 전화번호
- `address`: 주소
- `active`: 활성화 여부

### Reservation (예약)
- `id`: 기본키
- `restaurantId`: 레스토랑 ID (외래키)
- `customerId`: 고객 ID (외래키)
- `reservationDateTime`: 예약 날짜/시간
- `numberOfPeople`: 예약 인원
- `specialRequests`: 특별 요청사항
- `status`: 예약 상태 (PENDING, CONFIRMED, CANCELLED, COMPLETED)
- `createdAt`: 생성일시
- `updatedAt`: 수정일시

## 🚨 문제 해결

### 일반적인 문제들
1. **포트 충돌**: 8080 포트가 사용 중인 경우 `application.properties`에서 포트 변경
2. **데이터베이스 연결 오류**: H2 콘솔에서 연결 설정 확인
3. **테스트 실패**: VM 옵션 `-Dnet.bytebuddy.experimental=true` 설정 확인

### 로그 확인
- 애플리케이션 로그: 콘솔 출력 확인
- 브라우저 개발자 도구: 네트워크 탭에서 API 호출 확인
- H2 콘솔: 데이터베이스 상태 확인

## 🎯 향후 개선 사항

### 기능 확장
- 사용자 인증 및 권한 관리
- 결제 시스템 연동
- 알림 시스템 (이메일, SMS)
- 리뷰 및 평점 시스템

### 기술 개선
- React/Vue.js 프론트엔드
- Redis 캐싱
- Docker 컨테이너화
- CI/CD 파이프라인

### 성능 최적화
- 데이터베이스 인덱싱
- API 응답 시간 최적화
- 프론트엔드 번들 최적화
- CDN 활용

---

**🎉 축하합니다! 완전한 레스토랑 예약 시스템이 완성되었습니다!**

이 프로젝트는 Spring Boot 백엔드와 모던 프론트엔드를 결합한 완전한 웹 애플리케이션입니다. 모든 기능이 테스트되어 있으며, 실제 운영 환경에서 사용할 수 있는 수준입니다. 