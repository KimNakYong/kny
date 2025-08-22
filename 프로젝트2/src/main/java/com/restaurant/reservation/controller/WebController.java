package com.restaurant.reservation.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class WebController {

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/restaurants")
    public String restaurants() {
        return "restaurants";
    }

    @GetMapping("/reservations")
    public String reservations() {
        return "reservations";
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    @GetMapping("/signup")
    public String signup() {
        return "signup";
    }

    @GetMapping("/admin")
    public String admin() {
        return "admin";
    }

    @GetMapping("/restaurants/{id}")
    public String restaurantDetail() {
        return "restaurant-detail";
    }

    @GetMapping("/reservations/new")
    public String newReservation() {
        return "new-reservation";
    }
} 