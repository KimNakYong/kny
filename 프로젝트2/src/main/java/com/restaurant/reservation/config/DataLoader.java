package com.restaurant.reservation.config;

import com.restaurant.reservation.entity.Restaurant;
import com.restaurant.reservation.entity.Customer;
import com.restaurant.reservation.repository.RestaurantRepository;
import com.restaurant.reservation.repository.CustomerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
public class DataLoader implements CommandLineRunner {

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private Environment environment;

    @Override
    public void run(String... args) throws Exception {
        // 테스트 환경에서는 데이터 로딩을 건너뜀
        if (isTestProfile()) {
            return;
        }

        try {
            // 샘플 레스토랑 데이터 생성
            if (restaurantRepository.count() == 0) {
                createSampleRestaurants();
            }

            // 샘플 고객 데이터 생성
            if (customerRepository.count() == 0) {
                createSampleCustomers();
            }
        } catch (Exception e) {
            // 데이터 로딩 실패 시 로그만 출력하고 계속 진행
            System.err.println("Failed to load sample data: " + e.getMessage());
        }
    }

    private boolean isTestProfile() {
        for (String profile : environment.getActiveProfiles()) {
            if ("test".equals(profile)) {
                return true;
            }
        }
        return false;
    }

    private void createSampleRestaurants() {
        try {
            Restaurant restaurant1 = new Restaurant();
            restaurant1.setName("맛있는 한식당");
            restaurant1.setAddress("서울시 강남구 테헤란로 123");
            restaurant1.setPhone("02-1234-5678");
            restaurant1.setDescription("전통 한식과 현대적 감각이 조화를 이룬 프리미엄 한식당");
            restaurant1.setCapacity(50);
            restaurant1.setOpeningHours("11:00-22:00");
            restaurant1.setActive(true);
            restaurantRepository.save(restaurant1);

            Restaurant restaurant2 = new Restaurant();
            restaurant2.setName("이탈리안 피자");
            restaurant2.setAddress("서울시 서초구 서초대로 456");
            restaurant2.setPhone("02-2345-6789");
            restaurant2.setDescription("정통 이탈리아 피자와 파스타를 맛볼 수 있는 레스토랑");
            restaurant2.setCapacity(30);
            restaurant2.setOpeningHours("12:00-21:00");
            restaurant2.setActive(true);
            restaurantRepository.save(restaurant2);

            Restaurant restaurant3 = new Restaurant();
            restaurant3.setName("스시 마스터");
            restaurant3.setAddress("서울시 마포구 홍대로 789");
            restaurant3.setPhone("02-3456-7890");
            restaurant3.setDescription("신선한 회와 정통 스시를 제공하는 일본 레스토랑");
            restaurant3.setCapacity(20);
            restaurant3.setOpeningHours("11:30-22:30");
            restaurant3.setActive(true);
            restaurantRepository.save(restaurant3);
        } catch (Exception e) {
            System.err.println("Failed to create sample restaurants: " + e.getMessage());
        }
    }

    private void createSampleCustomers() {
        try {
            Customer customer1 = new Customer();
            customer1.setName("김철수");
            customer1.setEmail("kim@example.com");
            customer1.setPhone("010-1234-5678");
            customer1.setAddress("서울시 강남구");
            customer1.setActive(true);
            customerRepository.save(customer1);

            Customer customer2 = new Customer();
            customer2.setName("이영희");
            customer2.setEmail("lee@example.com");
            customer2.setPhone("010-2345-6789");
            customer2.setAddress("서울시 서초구");
            customer2.setActive(true);
            customerRepository.save(customer2);

            Customer customer3 = new Customer();
            customer3.setName("박민수");
            customer3.setEmail("park@example.com");
            customer3.setPhone("010-3456-7890");
            customer3.setAddress("서울시 마포구");
            customer3.setActive(true);
            customerRepository.save(customer3);
        } catch (Exception e) {
            System.err.println("Failed to create sample customers: " + e.getMessage());
        }
    }
} 