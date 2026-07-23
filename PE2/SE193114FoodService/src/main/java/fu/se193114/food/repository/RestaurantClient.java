package fu.se193114.food.repository;

import fu.se193114.food.dto.RestaurantApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "restaurant-service", url = "http://localhost:8081")
public interface RestaurantClient {

    @GetMapping("/api/restaurants/{id}")
    RestaurantApiResponse getRestaurantById(@PathVariable("id") Long id);
}
