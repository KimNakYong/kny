package com.restaurant.reservation.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import com.restaurant.reservation.entity.ReservationStatus;

@Entity
public class Reservation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private Restaurant restaurant;

    @ManyToOne
    private Customer customer;

    private LocalDateTime reservationDateTime;
    private int numberOfPeople;
    private String specialRequests;

    @Enumerated(EnumType.STRING)
    private ReservationStatus status;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // 기본 생성자
    public Reservation() {}

    // Getter 메서드들
    public Long getId() { return id; }
    public Restaurant getRestaurant() { return restaurant; }
    public Customer getCustomer() { return customer; }
    public LocalDateTime getReservationDateTime() { return reservationDateTime; }
    public int getNumberOfPeople() { return numberOfPeople; }
    public String getSpecialRequests() { return specialRequests; }
    public ReservationStatus getStatus() { 
        return status != null ? status : ReservationStatus.PENDING; 
    }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    // Setter 메서드들
    public void setId(Long id) { this.id = id; }
    public void setRestaurant(Restaurant restaurant) { this.restaurant = restaurant; }
    public void setCustomer(Customer customer) { this.customer = customer; }
    public void setReservationDateTime(LocalDateTime reservationDateTime) { this.reservationDateTime = reservationDateTime; }
    public void setNumberOfPeople(int numberOfPeople) { this.numberOfPeople = numberOfPeople; }
    public void setSpecialRequests(String specialRequests) { this.specialRequests = specialRequests; }
    public void setStatus(ReservationStatus status) { 
        this.status = status; 
    }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}