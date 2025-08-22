package com.restaurant.reservation.service;

import com.restaurant.reservation.entity.Restaurant;
import com.restaurant.reservation.repository.RestaurantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RestaurantServiceTest {

    @Mock
    private RestaurantRepository restaurantRepository;

    @InjectMocks
    private RestaurantService restaurantService;

    private Restaurant testRestaurant;

    @BeforeEach
    void setUp() {
        testRestaurant = new Restaurant();
        testRestaurant.setId(1L);
        testRestaurant.setName("테스트 레스토랑");
        testRestaurant.setAddress("서울시 강남구");
        testRestaurant.setPhone("02-1234-5678");
        testRestaurant.setDescription("테스트용 레스토랑");
        testRestaurant.setCapacity(30);
        testRestaurant.setOpeningHours("11:00-22:00");
        testRestaurant.setActive(true);
    }

    @Test
    void testGetAllRestaurants() {
        // Given
        List<Restaurant> expectedRestaurants = Arrays.asList(testRestaurant);
        when(restaurantRepository.findByIsActiveTrue()).thenReturn(expectedRestaurants);

        // When
        List<Restaurant> actualRestaurants = restaurantService.getAllRestaurants();

        // Then
        assertEquals(expectedRestaurants.size(), actualRestaurants.size());
        assertEquals(testRestaurant.getName(), actualRestaurants.get(0).getName());
        verify(restaurantRepository, times(1)).findByIsActiveTrue();
    }

    @Test
    void testGetRestaurantById() {
        // Given
        when(restaurantRepository.findById(1L)).thenReturn(Optional.of(testRestaurant));

        // When
        Optional<Restaurant> actualRestaurant = restaurantService.getRestaurantById(1L);

        // Then
        assertTrue(actualRestaurant.isPresent());
        assertEquals(testRestaurant.getName(), actualRestaurant.get().getName());
        verify(restaurantRepository, times(1)).findById(1L);
    }

    @Test
    void testGetRestaurantByIdNotFound() {
        // Given
        when(restaurantRepository.findById(999L)).thenReturn(Optional.empty());

        // When
        Optional<Restaurant> actualRestaurant = restaurantService.getRestaurantById(999L);

        // Then
        assertFalse(actualRestaurant.isPresent());
        verify(restaurantRepository, times(1)).findById(999L);
    }

    @Test
    void testSaveRestaurant() {
        // Given
        when(restaurantRepository.save(any(Restaurant.class))).thenReturn(testRestaurant);

        // When
        Restaurant savedRestaurant = restaurantService.saveRestaurant(testRestaurant);

        // Then
        assertNotNull(savedRestaurant);
        assertEquals(testRestaurant.getName(), savedRestaurant.getName());
        verify(restaurantRepository, times(1)).save(testRestaurant);
    }

    @Test
    void testDeleteRestaurant() {
        // Given
        when(restaurantRepository.findById(1L)).thenReturn(Optional.of(testRestaurant));
        when(restaurantRepository.save(any(Restaurant.class))).thenReturn(testRestaurant);

        // When
        restaurantService.deleteRestaurant(1L);

        // Then
        verify(restaurantRepository, times(1)).findById(1L);
        verify(restaurantRepository, times(1)).save(any(Restaurant.class));
        assertFalse(testRestaurant.isActive());
    }

    @Test
    void testSearchRestaurantsByName() {
        // Given
        List<Restaurant> expectedRestaurants = Arrays.asList(testRestaurant);
        when(restaurantRepository.findByNameContainingIgnoreCase("테스트")).thenReturn(expectedRestaurants);

        // When
        List<Restaurant> actualRestaurants = restaurantService.searchRestaurantsByName("테스트");

        // Then
        assertEquals(expectedRestaurants.size(), actualRestaurants.size());
        assertEquals(testRestaurant.getName(), actualRestaurants.get(0).getName());
        verify(restaurantRepository, times(1)).findByNameContainingIgnoreCase("테스트");
    }
} 