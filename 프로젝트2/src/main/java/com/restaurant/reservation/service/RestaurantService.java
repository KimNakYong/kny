package com.restaurant.reservation.service;

import com.restaurant.reservation.entity.Restaurant;
import com.restaurant.reservation.repository.RestaurantRepository;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

// 레스토랑 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.
@Service
public class RestaurantService {
    private final RestaurantRepository restaurantRepository;

    public RestaurantService(RestaurantRepository restaurantRepository) {
        this.restaurantRepository = restaurantRepository;
    }

    public List<Restaurant> getAllRestaurants() {
        try {
            return restaurantRepository.findByIsActiveTrue();
        } catch (Exception e) {
            return List.of();
        }
    }

    public Optional<Restaurant> getRestaurantById(Long id) {
        try {
            return restaurantRepository.findById(id);
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    public Restaurant saveRestaurant(Restaurant restaurant) {
        try {
            return restaurantRepository.save(restaurant);
        } catch (Exception e) {
            throw new RuntimeException("Failed to save restaurant", e);
        }
    }

    public Restaurant createRestaurant(Restaurant restaurant) {
        try {
            return restaurantRepository.save(restaurant);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create restaurant", e);
        }
    }

    public List<Restaurant> searchRestaurants(String name, String address) {
        try {
            return restaurantRepository.findByNameContainingAndAddressContaining(name, address);
        } catch (Exception e) {
            return List.of();
        }
    }

    public List<Restaurant> searchRestaurantsByName(String name) {
        try {
            return restaurantRepository.findByNameContainingIgnoreCase(name);
        } catch (Exception e) {
            return List.of();
        }
    }

    public List<Restaurant> searchRestaurantsByAddress(String address) {
        try {
            return restaurantRepository.findByAddressContainingIgnoreCase(address);
        } catch (Exception e) {
            return List.of();
        }
    }

    public void deleteRestaurant(Long id) {
        try {
            restaurantRepository.findById(id).ifPresent(restaurant -> {
                restaurant.setActive(false);
                restaurantRepository.save(restaurant);
            });
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete restaurant", e);
        }
    }
}