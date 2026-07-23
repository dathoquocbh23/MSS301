package fu.se193114.restaurant.common;

import fu.se193114.restaurant.dto.RestaurantDTO;
import fu.se193114.restaurant.entity.Restaurant;

public final class RestaurantMapper {

    private RestaurantMapper() {
    }

    public static RestaurantDTO toDTO(Restaurant entity) {
        if (entity == null) {
            return null;
        }
        RestaurantDTO dto = new RestaurantDTO();
        dto.setRestaurantId(entity.getRestaurantId());
        dto.setName(entity.getName());
        dto.setOwner(entity.getOwner());
        dto.setPriceFrom(entity.getPriceFrom());
        dto.setPriceTo(entity.getPriceTo());
        dto.setPhone(entity.getPhone());
        dto.setAddress(entity.getAddress());
        dto.setOpenDate(entity.getOpenDate());
        dto.setStatus(entity.getStatus());
        dto.setCategoryId(entity.getCategoryId());
        return dto;
    }

    public static Restaurant toEntity(RestaurantDTO dto) {
        if (dto == null) {
            return null;
        }
        Restaurant entity = new Restaurant();
        entity.setRestaurantId(dto.getRestaurantId());
        entity.setName(dto.getName());
        entity.setOwner(dto.getOwner());
        entity.setPriceFrom(dto.getPriceFrom());
        entity.setPriceTo(dto.getPriceTo());
        entity.setPhone(dto.getPhone());
        entity.setAddress(dto.getAddress());
        entity.setOpenDate(dto.getOpenDate());
        entity.setStatus(dto.getStatus());
        entity.setCategoryId(dto.getCategoryId());
        return entity;
    }
}
