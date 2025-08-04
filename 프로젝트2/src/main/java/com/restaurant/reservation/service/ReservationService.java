package com.restaurant.reservation.service;

import com.restaurant.reservation.entity.Reservation;
import com.restaurant.reservation.entity.ReservationStatus;
import com.restaurant.reservation.repository.ReservationRepository;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

// 예약 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.
@Service
public class ReservationService {
    private final ReservationRepository reservationRepository;

    public ReservationService(ReservationRepository reservationRepository) {
        this.reservationRepository = reservationRepository;
    }

    public List<Reservation> getAllReservations() {
        try {
            return reservationRepository.findAll();
        } catch (Exception e) {
            return List.of(); // 빈 리스트 반환
        }
    }

    public Optional<Reservation> getReservationById(Long id) {
        try {
            return reservationRepository.findById(id);
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    public List<Reservation> getReservationsByRestaurant(Long restaurantId) {
        try {
            return reservationRepository.findByRestaurantId(restaurantId);
        } catch (Exception e) {
            return List.of();
        }
    }

    public List<Reservation> getReservationsByCustomer(Long customerId) {
        try {
            return reservationRepository.findByCustomerId(customerId);
        } catch (Exception e) {
            return List.of();
        }
    }

    public Reservation createReservation(Reservation reservation) {
        try {
            if (reservation == null) {
                reservation = new Reservation();
            }
            return reservationRepository.save(reservation);
        } catch (Exception e) {
            Reservation newReservation = new Reservation();
            return reservationRepository.save(newReservation);
        }
    }

    public Reservation updateReservationStatus(Long id, ReservationStatus status) {
        try {
            Reservation reservation = reservationRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Reservation not found"));
            reservation.setStatus(status);
            reservation.setUpdatedAt(LocalDateTime.now());
            return reservationRepository.save(reservation);
        } catch (Exception e) {
            throw new RuntimeException("Failed to update reservation status", e);
        }
    }

    public void cancelReservation(Long id) {
        try {
            Reservation reservation = reservationRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Reservation not found"));
            reservation.setStatus(ReservationStatus.CANCELLED);
            reservation.setUpdatedAt(LocalDateTime.now());
            reservationRepository.save(reservation);
        } catch (Exception e) {
            throw new RuntimeException("Failed to cancel reservation", e);
        }
    }

    public List<Reservation> getReservationsByStatus(ReservationStatus status) {
        try {
            return reservationRepository.findByStatus(status);
        } catch (Exception e) {
            return List.of();
        }
    }
}