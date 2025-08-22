package com.restaurant.reservation.service;

import com.restaurant.reservation.entity.Customer;
import com.restaurant.reservation.repository.CustomerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
public class CustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    public List<Customer> getAllCustomers() {
        try {
            return customerRepository.findAll();
        } catch (Exception e) {
            return List.of();
        }
    }
    
    public Optional<Customer> getCustomerById(Long id) {
        try {
            return customerRepository.findById(id);
        } catch (Exception e) {
            return Optional.empty();
        }
    }
    
    public Optional<Customer> getCustomerByEmail(String email) {
        try {
            return customerRepository.findByEmail(email);
        } catch (Exception e) {
            return Optional.empty();
        }
    }
    
    public Customer saveCustomer(Customer customer) {
        try {
            return customerRepository.save(customer);
        } catch (Exception e) {
            throw new RuntimeException("Failed to save customer", e);
        }
    }
    
    public void deleteCustomer(Long id) {
        try {
            Optional<Customer> customer = customerRepository.findById(id);
            if (customer.isPresent()) {
                Customer c = customer.get();
                c.setActive(false);
                customerRepository.save(c);
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete customer", e);
        }
    }
    
    public boolean customerExists(String email) {
        try {
            return customerRepository.existsByEmail(email);
        } catch (Exception e) {
            return false;
        }
    }

    public Customer createCustomer(Customer customer) {
        try {
            if (customer == null) {
                throw new IllegalArgumentException("고객 정보가 null입니다.");
            }
            return customerRepository.save(customer);
        } catch (Exception e) {
            throw new RuntimeException("고객 생성에 실패했습니다.", e);
        }
    }

    public Customer findByEmail(String email) {
        try {
            if (email == null || email.trim().isEmpty()) {
                return null;
            }
            Optional<Customer> customer = customerRepository.findByEmail(email);
            return customer.orElse(null);
        } catch (Exception e) {
            throw new RuntimeException("이메일로 고객을 찾는데 실패했습니다.", e);
        }
    }
} 