package com.restaurant.reservation.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.restaurant.reservation.entity.Restaurant;
import com.restaurant.reservation.repository.RestaurantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@Transactional
class RestaurantControllerIntegrationTest {

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        // 테스트 전 데이터베이스 초기화
        restaurantRepository.deleteAll();
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
    }

    @Test
    void testCreateAndGetRestaurant() throws Exception {
        // Given
        Restaurant restaurant = new Restaurant();
        restaurant.setName("통합 테스트 레스토랑");
        restaurant.setAddress("서울시 강남구");
        restaurant.setPhone("02-1234-5678");
        restaurant.setDescription("통합 테스트용 레스토랑");
        restaurant.setCapacity(30);
        restaurant.setOpeningHours("11:00-22:00");
        restaurant.setActive(true);

        // When & Then - Create
        String response = mockMvc.perform(post("/api/restaurants")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(restaurant)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("통합 테스트 레스토랑"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        Restaurant createdRestaurant = objectMapper.readValue(response, Restaurant.class);

        // When & Then - Get by ID
        mockMvc.perform(get("/api/restaurants/" + createdRestaurant.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(createdRestaurant.getId()))
                .andExpect(jsonPath("$.name").value("통합 테스트 레스토랑"));
    }

    @Test
    void testGetAllRestaurants() throws Exception {
        // Given
        Restaurant restaurant1 = new Restaurant();
        restaurant1.setName("레스토랑 1");
        restaurant1.setAddress("서울시 강남구");
        restaurant1.setPhone("02-1111-1111");
        restaurant1.setDescription("첫 번째 레스토랑");
        restaurant1.setCapacity(20);
        restaurant1.setOpeningHours("11:00-21:00");
        restaurant1.setActive(true);
        restaurantRepository.save(restaurant1);

        Restaurant restaurant2 = new Restaurant();
        restaurant2.setName("레스토랑 2");
        restaurant2.setAddress("서울시 서초구");
        restaurant2.setPhone("02-2222-2222");
        restaurant2.setDescription("두 번째 레스토랑");
        restaurant2.setCapacity(30);
        restaurant2.setOpeningHours("12:00-22:00");
        restaurant2.setActive(true);
        restaurantRepository.save(restaurant2);

        // When & Then
        mockMvc.perform(get("/api/restaurants"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void testSearchRestaurants() throws Exception {
        // Given
        Restaurant restaurant = new Restaurant();
        restaurant.setName("검색 테스트 레스토랑");
        restaurant.setAddress("서울시 강남구 테헤란로");
        restaurant.setPhone("02-3333-3333");
        restaurant.setDescription("검색 테스트용 레스토랑");
        restaurant.setCapacity(25);
        restaurant.setOpeningHours("11:30-21:30");
        restaurant.setActive(true);
        restaurantRepository.save(restaurant);

        // When & Then - Search by name
        mockMvc.perform(get("/api/restaurants/search")
                        .param("name", "검색"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("검색 테스트 레스토랑"));

        // When & Then - Search by address
        mockMvc.perform(get("/api/restaurants/search")
                        .param("address", "테헤란로"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].address").value("서울시 강남구 테헤란로"));
    }
} 