// 레스토랑 엔티티의 데이터베이스 접근을 위한 JPA 리포지토리입니다.
package com.restaurant.reservation.repository;

import com.restaurant.reservation.entity.Restaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RestaurantRepository extends JpaRepository<Restaurant, Long> {
    // 이름과 주소로 레스토랑 검색
    List<Restaurant> findByNameContainingAndAddressContaining(String name, String address);
    
    // 활성화된 레스토랑만 조회
    List<Restaurant> findByIsActiveTrue();
    
    // 이름으로 레스토랑 검색 (대소문자 무시)
    List<Restaurant> findByNameContainingIgnoreCase(String name);
    
    // 주소로 레스토랑 검색 (대소문자 무시)
    List<Restaurant> findByAddressContainingIgnoreCase(String address);
}