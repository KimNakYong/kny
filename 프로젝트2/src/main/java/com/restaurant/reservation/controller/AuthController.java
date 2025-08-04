package com.restaurant.reservation.controller;

import com.restaurant.reservation.entity.Customer;
import com.restaurant.reservation.service.CustomerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private CustomerService customerService;

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody Map<String, Object> request) {
        try {
            // 고객 정보 생성
            Customer customer = new Customer();
            customer.setName(request.get("firstName") + " " + request.get("lastName"));
            customer.setEmail((String) request.get("email"));
            customer.setPhone((String) request.get("phone"));
            customer.setAddress((String) request.get("address"));
            customer.setActive(true);

            // 비밀번호는 실제 구현에서는 암호화해야 함
            // 여기서는 간단히 저장 (실제로는 BCrypt 등 사용)
            String password = (String) request.get("password");
            // customer.setPassword(password); // 실제로는 암호화된 비밀번호 저장

            Customer savedCustomer = customerService.createCustomer(customer);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "회원가입이 성공적으로 완료되었습니다.");
            response.put("customerId", savedCustomer.getId());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "회원가입 중 오류가 발생했습니다: " + e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, Object> request) {
        try {
            String email = (String) request.get("email");
            String password = (String) request.get("password");
            
            // 실제 구현에서는 비밀번호 검증 로직 필요
            Customer customer = customerService.findByEmail(email);
            
            if (customer == null) {
                Map<String, String> error = new HashMap<>();
                error.put("message", "이메일 또는 비밀번호가 올바르지 않습니다.");
                return ResponseEntity.badRequest().body(error);
            }
            
            // 실제 구현에서는 비밀번호 검증
            // if (!passwordEncoder.matches(password, customer.getPassword())) {
            //     return ResponseEntity.badRequest().body("비밀번호가 올바르지 않습니다.");
            // }
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "로그인이 성공적으로 완료되었습니다.");
            response.put("token", "dummy-token-" + System.currentTimeMillis()); // 실제로는 JWT 토큰 생성
            response.put("email", customer.getEmail());
            response.put("name", customer.getName());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "로그인 중 오류가 발생했습니다: " + e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @GetMapping("/check-email")
    public ResponseEntity<?> checkEmail(@RequestParam String email) {
        try {
            Customer customer = customerService.findByEmail(email);
            Map<String, Boolean> response = new HashMap<>();
            response.put("available", customer == null);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "이메일 확인 중 오류가 발생했습니다.");
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "로그아웃이 성공적으로 완료되었습니다.");
        return ResponseEntity.ok(response);
    }
} 