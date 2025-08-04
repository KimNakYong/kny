// 레스토랑 정보를 저장하는 엔티티 클래스입니다.
package com.restaurant.reservation.entity;

import jakarta.persistence.*;

@Entity
public class Restaurant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // 레스토랑 고유 ID

    private String name; // 레스토랑명
    private String address; // 주소
    private String phone; // 전화번호
    private String description; // 설명
    private int capacity; // 수용 인원
    private String openingHours; // 영업시간
    private boolean isActive; // 활성화 여부

    // 기본 생성자
    public Restaurant() {}

    // Getter 메서드들
    public Long getId() { return id; }
    public String getName() { return name; }
    public String getAddress() { return address; }
    public String getPhone() { return phone; }
    public String getDescription() { return description; }
    public int getCapacity() { return capacity; }
    public String getOpeningHours() { return openingHours; }
    public boolean isActive() { return isActive; }

    // Setter 메서드들
    public void setId(Long id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setAddress(String address) { this.address = address; }
    public void setPhone(String phone) { this.phone = phone; }
    public void setDescription(String description) { this.description = description; }
    public void setCapacity(int capacity) { this.capacity = capacity; }
    public void setOpeningHours(String openingHours) { this.openingHours = openingHours; }
    public void setActive(boolean active) { this.isActive = active; }
}