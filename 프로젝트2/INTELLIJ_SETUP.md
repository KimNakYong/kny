# IntelliJ IDEA 설정 가이드

## 1. 프로젝트 JDK 설정

### 1.1 JDK 버전 확인
- **File** → **Project Structure** → **Project Settings** → **Project**
- **Project SDK**: Java 17로 설정되어 있는지 확인
- **Project language level**: 17로 설정

### 1.2 모듈 설정
- **File** → **Project Structure** → **Project Settings** → **Modules**
- **Language level**: 17로 설정

## 2. Maven 설정

### 2.1 Maven 프로젝트 새로고침
- **View** → **Tool Windows** → **Maven**
- Maven 탭에서 **Reload All Maven Projects** 버튼 클릭

### 2.2 Maven 설정 확인
- **File** → **Settings** → **Build, Execution, Deployment** → **Build Tools** → **Maven**
- **Maven home path**: 올바른 Maven 경로 설정
- **User settings file**: `settings.xml` 파일 경로 확인

## 3. 테스트 실행 설정

### 3.1 VM 옵션 설정 (중요!)
Java 24 호환성 문제를 해결하기 위해 VM 옵션을 설정해야 합니다:

1. **Run** → **Edit Configurations**
2. **Templates** → **JUnit** 선택
3. **VM options** 필드에 다음 추가:
   ```
   -Dnet.bytebuddy.experimental=true
   ```
4. **Apply** → **OK**

### 3.2 개별 테스트 실행 설정
각 테스트 클래스에 대해:
1. 테스트 클래스 우클릭 → **Modify Run Configuration**
2. **VM options** 필드에 추가:
   ```
   -Dnet.bytebuddy.experimental=true
   ```

## 4. 캐시 초기화

### 4.1 IntelliJ 캐시 초기화
- **File** → **Invalidate Caches and Restart**
- **Invalidate and Restart** 선택

### 4.2 프로젝트 재빌드
- **Build** → **Rebuild Project**

## 5. 테스트 실행

### 5.1 전체 테스트 실행
- **Run** → **Run All Tests**
- 또는 Maven 탭에서 `test` 목표 실행

### 5.2 개별 테스트 실행
- 테스트 클래스 또는 메서드 우클릭 → **Run 'TestName'**

## 6. 문제 해결

### 6.1 Java 버전 불일치 문제
만약 여전히 Java 24 관련 오류가 발생한다면:

1. **File** → **Project Structure** → **Project Settings** → **SDKs**
2. Java 17 JDK가 설정되어 있는지 확인
3. **File** → **Settings** → **Build, Execution, Deployment** → **Compiler** → **Java Compiler**
4. **Target bytecode version**: 17로 설정

### 6.2 Maven 설정 확인
```bash
mvn --version
```
출력에서 Java 버전이 17인지 확인

### 6.3 환경 변수 확인
- `JAVA_HOME`: Java 17 JDK 경로로 설정
- `PATH`: Java 17 bin 디렉토리가 포함되어 있는지 확인

## 7. 추가 설정

### 7.1 테스트 프로파일 활성화
테스트 클래스에 `@ActiveProfiles("test")` 어노테이션이 있는지 확인

### 7.2 로깅 설정
테스트 실행 시 로그 레벨을 조정하려면 `application-test.properties`에서 설정

## 8. 성공적인 테스트 실행 확인

모든 설정이 완료되면:
1. **Build** → **Rebuild Project**
2. **Run** → **Run All Tests**
3. 모든 테스트가 성공적으로 실행되는지 확인

## 주의사항

- Java 24가 시스템에 설치되어 있다면, IntelliJ가 이를 사용할 수 있습니다
- `pom.xml`에서 Java 17을 명시했지만, IDE 설정에서 올바른 JDK를 사용하는지 확인하세요
- VM 옵션 `-Dnet.bytebuddy.experimental=true`는 반드시 설정해야 합니다 