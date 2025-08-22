// Spring Boot 애플리케이션의 진입점입니다.
package com.restaurant.reservation;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ReservationApplication {
    public static void main(String[] args) {
        // 애플리케이션 실행
        SpringApplication.run(ReservationApplication.class, args);
    }
}