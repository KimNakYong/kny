# Java 버전 호환성 문제 해결 가이드

## 🚨 현재 문제 상황

### 오류 메시지
```
java: java.lang.ExceptionInInitializerError
com.sun.tools.javac.code.TypeTag :: UNKNOWN
```

### 원인 분석
- **현재 Java 버전**: 24.0.1 (매우 최신)
- **프로젝트 설정**: Java 17
- **Spring Boot 버전**: 3.2.0
- **문제**: Java 24와 Spring Boot 3.2.0 간의 호환성 문제

## 🔧 해결 방법

### 방법 1: Java 17 설치 및 사용 (권장)

#### 1. Java 17 다운로드
1. [Oracle JDK 17](https://www.oracle.com/java/technologies/downloads/#java17) 또는 [OpenJDK 17](https://adoptium.net/temurin/releases/?version=17) 다운로드
2. Windows x64 Installer 선택

#### 2. Java 17 설치
1. 다운로드한 설치 파일 실행
2. 기본 설정으로 설치 진행
3. 설치 완료 후 시스템 재시작

#### 3. 환경 변수 설정
1. `시스템 환경 변수 편집` → `환경 변수`
2. `시스템 변수`에서 `JAVA_HOME` 설정:
   ```
   JAVA_HOME = C:\Program Files\Java\jdk-17
   ```
3. `Path` 변수에 추가:
   ```
   %JAVA_HOME%\bin
   ```

#### 4. Java 버전 확인
```bash
java -version
javac -version
```

### 방법 2: 프로젝트 Java 버전 업데이트 (대안)

#### 1. pom.xml 수정
```xml
<properties>
    <java.version>21</java.version>
</properties>
```

#### 2. Spring Boot 버전 업데이트
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.0</version>
    <relativePath/>
</parent>
```

### 방법 3: IntelliJ에서 Java 버전 설정

#### 1. Project Structure 설정
1. `File` → `Project Structure` (`Ctrl+Alt+Shift+S`)
2. `Project` 탭에서 SDK를 Java 17로 설정
3. `Modules` 탭에서 Language Level을 17로 설정

#### 2. Maven 설정
1. `File` → `Settings` → `Build Tools` → `Maven` → `Runner`
2. `JRE`를 Java 17로 설정

## 🧪 테스트 실행

### 1. Java 버전 확인 후 테스트
```bash
# 프로젝트 디렉토리에서
.\mvnw.cmd clean test
```

### 2. IntelliJ에서 테스트
1. `src/test/java` 폴더 우클릭
2. `Run 'All Tests'` 선택

## 🚨 추가 문제 해결

### 1. Lombok 관련 오류
- Lombok 플러그인 설치 확인
- Annotation Processing 활성화

### 2. Maven 캐시 클리어
```bash
.\mvnw.cmd clean
```

### 3. IntelliJ 캐시 클리어
- `File` → `Invalidate Caches and Restart`

## 📋 권장 사항

### 1. Java 버전 선택
- **개발용**: Java 17 (LTS)
- **최신 기능**: Java 21 (LTS)
- **실험적**: Java 24 (최신)

### 2. Spring Boot 버전
- **안정적**: 3.2.x
- **최신**: 3.3.x

### 3. 프로젝트 설정
```xml
<properties>
    <java.version>17</java.version>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
</properties>
```

## 🎯 최종 확인

모든 설정 완료 후:
1. Java 버전 확인: `java -version`
2. Maven 빌드: `.\mvnw.cmd clean compile`
3. 테스트 실행: `.\mvnw.cmd test`

**Java 17 설치가 가장 안정적인 해결책입니다!** 🎯 