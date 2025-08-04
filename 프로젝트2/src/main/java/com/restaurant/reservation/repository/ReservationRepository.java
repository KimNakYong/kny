package com.restaurant.reservation.repository;

import com.restaurant.reservation.entity.Reservation;
import com.restaurant.reservation.entity.ReservationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

// 예약 엔티티의 데이터베이스 접근을 위한 JPA 리포지토리입니다.
public interface ReservationRepository extends JpaRepository<Reservation, Long> {
    // 레스토랑별 예약 조회
    List<Reservation> findByRestaurantId(Long restaurantId);
    
    // 고객별 예약 조회
    List<Reservation> findByCustomerId(Long customerId);
    
    // 상태별 예약 조회
    List<Reservation> findByStatus(ReservationStatus status);
}