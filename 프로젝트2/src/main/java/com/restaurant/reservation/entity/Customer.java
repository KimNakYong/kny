// 고객 정보를 저장하는 엔티티 클래스입니다.
package com.restaurant.reservation.entity;

import jakarta.persistence.*;

@Entity
public class Customer {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // 고객 고유 ID

    private String name; // 고객명

    @Column(unique = true)
    private String email; // 이메일(고유)

    private String phone; // 전화번호
    private String address; // 주소
    private boolean isActive; // 활성화 여부

    // 기본 생성자
    public Customer() {}

    // Getter 메서드들
    public Long getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public String getAddress() { return address; }
    public boolean isActive() { return isActive; }

    // Setter 메서드들
    public void setId(Long id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setEmail(String email) { this.email = email; }
    public void setPhone(String phone) { this.phone = phone; }
    public void setAddress(String address) { this.address = address; }
    public void setActive(boolean active) { this.isActive = active; }
}