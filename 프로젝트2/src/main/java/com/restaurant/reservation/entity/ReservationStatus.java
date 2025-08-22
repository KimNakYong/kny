package com.restaurant.reservation.entity;

/**
 * 예약 상태를 나타내는 enum
 */
public enum ReservationStatus {
    PENDING,    // 예약 대기
    CONFIRMED,  // 예약 확정
    CANCELLED,  // 예약 취소
    COMPLETED   // 예약 완료
}
