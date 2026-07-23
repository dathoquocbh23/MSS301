package fu.se193114.restaurant.service;

import fu.se193114.restaurant.dto.PageDTO;
import fu.se193114.restaurant.dto.RestaurantDTO;

public interface RestaurantService {

    RestaurantDTO create(RestaurantDTO dto);

    RestaurantDTO update(Long restaurantId, RestaurantDTO dto);

    RestaurantDTO getById(Long restaurantId);

    void softDelete(Long restaurantId);

    PageDTO list(Integer page, Integer size, String name, String ownerName);
}
