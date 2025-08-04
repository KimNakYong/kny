package com.restaurant.reservation.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.restaurant.reservation.entity.Restaurant;
import com.restaurant.reservation.service.RestaurantService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(RestaurantController.class)
class RestaurantControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private RestaurantService restaurantService;

    @Autowired
    private ObjectMapper objectMapper;

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
    void testGetAllRestaurants() throws Exception {
        // Given
        List<Restaurant> restaurants = Arrays.asList(testRestaurant);
        when(restaurantService.getAllRestaurants()).thenReturn(restaurants);

        // When & Then
        mockMvc.perform(get("/api/restaurants"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].name").value("테스트 레스토랑"))
                .andExpect(jsonPath("$[0].address").value("서울시 강남구"));
    }

    @Test
    void testGetRestaurantById() throws Exception {
        // Given
        when(restaurantService.getRestaurantById(1L)).thenReturn(Optional.of(testRestaurant));

        // When & Then
        mockMvc.perform(get("/api/restaurants/1"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("테스트 레스토랑"));
    }

    @Test
    void testGetRestaurantByIdNotFound() throws Exception {
        // Given
        when(restaurantService.getRestaurantById(999L)).thenReturn(Optional.empty());

        // When & Then
        mockMvc.perform(get("/api/restaurants/999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void testCreateRestaurant() throws Exception {
        // Given
        when(restaurantService.saveRestaurant(any(Restaurant.class))).thenReturn(testRestaurant);

        // When & Then
        mockMvc.perform(post("/api/restaurants")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(testRestaurant)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("테스트 레스토랑"));
    }

    @Test
    void testUpdateRestaurant() throws Exception {
        // Given
        when(restaurantService.getRestaurantById(1L)).thenReturn(Optional.of(testRestaurant));
        when(restaurantService.saveRestaurant(any(Restaurant.class))).thenReturn(testRestaurant);

        // When & Then
        mockMvc.perform(put("/api/restaurants/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(testRestaurant)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("테스트 레스토랑"));
    }

    @Test
    void testUpdateRestaurantNotFound() throws Exception {
        // Given
        when(restaurantService.getRestaurantById(999L)).thenReturn(Optional.empty());

        // When & Then
        mockMvc.perform(put("/api/restaurants/999")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(testRestaurant)))
                .andExpect(status().isNotFound());
    }

    @Test
    void testDeleteRestaurant() throws Exception {
        // When & Then
        mockMvc.perform(delete("/api/restaurants/1"))
                .andExpect(status().isOk());
    }

    @Test
    void testSearchRestaurantsByName() throws Exception {
        // Given
        List<Restaurant> restaurants = Arrays.asList(testRestaurant);
        when(restaurantService.searchRestaurantsByName(anyString())).thenReturn(restaurants);

        // When & Then
        mockMvc.perform(get("/api/restaurants/search")
                        .param("name", "테스트"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("테스트 레스토랑"));
    }

    @Test
    void testSearchRestaurantsByAddress() throws Exception {
        // Given
        List<Restaurant> restaurants = Arrays.asList(testRestaurant);
        when(restaurantService.searchRestaurantsByAddress(anyString())).thenReturn(restaurants);

        // When & Then
        mockMvc.perform(get("/api/restaurants/search")
                        .param("address", "강남구"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].address").value("서울시 강남구"));
    }
} 