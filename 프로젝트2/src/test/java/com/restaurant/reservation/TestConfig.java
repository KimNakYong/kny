package com.restaurant.reservation;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.test.context.ActiveProfiles;

/**
 * 테스트 환경을 위한 설정 클래스
 * IntelliJ에서 테스트 실행 시 사용됩니다.
 */
@TestConfiguration
@ActiveProfiles("test")
public class TestConfig {
    
    // 테스트용 설정이 필요한 경우 여기에 추가
    // 예: Mock Bean, Test용 설정 등
    
} 