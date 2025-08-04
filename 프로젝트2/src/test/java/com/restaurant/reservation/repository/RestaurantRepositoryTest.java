package com.restaurant.reservation.repository;

import com.restaurant.reservation.entity.Restaurant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest
@ActiveProfiles("test")
class RestaurantRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @BeforeEach
    void setUp() {
        // 테스트 전 데이터베이스 초기화
        restaurantRepository.deleteAll();
    }

    @Test
    void testSaveRestaurant() {
        // Given
        Restaurant restaurant = new Restaurant();
        restaurant.setName("테스트 레스토랑");
        restaurant.setAddress("서울시 강남구");
        restaurant.setPhone("02-1234-5678");
        restaurant.setDescription("테스트용 레스토랑");
        restaurant.setCapacity(30);
        restaurant.setOpeningHours("11:00-22:00");
        restaurant.setActive(true);

        // When
        Restaurant savedRestaurant = restaurantRepository.save(restaurant);

        // Then
        assertNotNull(savedRestaurant.getId());
        assertEquals("테스트 레스토랑", savedRestaurant.getName());
    }

    @Test
    void testFindByIsActiveTrue() {
        // Given
        Restaurant activeRestaurant = new Restaurant();
        activeRestaurant.setName("활성 레스토랑");
        activeRestaurant.setAddress("서울시 강남구");
        activeRestaurant.setPhone("02-1234-5678");
        activeRestaurant.setDescription("활성화된 레스토랑");
        activeRestaurant.setCapacity(30);
        activeRestaurant.setOpeningHours("11:00-22:00");
        activeRestaurant.setActive(true);
        entityManager.persist(activeRestaurant);

        Restaurant inactiveRestaurant = new Restaurant();
        inactiveRestaurant.setName("비활성 레스토랑");
        inactiveRestaurant.setAddress("서울시 서초구");
        inactiveRestaurant.setPhone("02-2345-6789");
        inactiveRestaurant.setDescription("비활성화된 레스토랑");
        inactiveRestaurant.setCapacity(20);
        inactiveRestaurant.setOpeningHours("12:00-21:00");
        inactiveRestaurant.setActive(false);
        entityManager.persist(inactiveRestaurant);

        entityManager.flush();

        // When
        List<Restaurant> activeRestaurants = restaurantRepository.findByIsActiveTrue();

        // Then
        assertEquals(1, activeRestaurants.size());
        assertEquals("활성 레스토랑", activeRestaurants.get(0).getName());
    }

    @Test
    void testFindByNameContainingIgnoreCase() {
        // Given
        Restaurant restaurant = new Restaurant();
        restaurant.setName("맛있는 한식당");
        restaurant.setAddress("서울시 강남구");
        restaurant.setPhone("02-1234-5678");
        restaurant.setDescription("한식당");
        restaurant.setCapacity(30);
        restaurant.setOpeningHours("11:00-22:00");
        restaurant.setActive(true);
        entityManager.persist(restaurant);
        entityManager.flush();

        // When
        List<Restaurant> foundRestaurants = restaurantRepository.findByNameContainingIgnoreCase("한식");

        // Then
        assertEquals(1, foundRestaurants.size());
        assertEquals("맛있는 한식당", foundRestaurants.get(0).getName());
    }
} 