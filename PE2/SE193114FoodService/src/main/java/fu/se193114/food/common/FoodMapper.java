package fu.se193114.food.common;

import fu.se193114.food.dto.FoodDTO;
import fu.se193114.food.dto.FoodResponseDTO;
import fu.se193114.food.dto.RestaurantDTO;
import fu.se193114.food.entity.Food;

public class FoodMapper {

    private FoodMapper() {
    }

    public static FoodDTO toDTO(Food entity) {
        if (entity == null) {
            return null;
        }
        FoodDTO dto = new FoodDTO();
        dto.setFoodId(entity.getFoodId());
        dto.setName(entity.getName());
        dto.setPrice(entity.getPrice());
        dto.setIngredients(entity.getIngredients());
        dto.setRestaurantId(entity.getRestaurantId());
        dto.setStatus(entity.getStatus());
        return dto;
    }

    public static FoodResponseDTO toResponseDTO(Food entity, RestaurantDTO restaurant) {
        if (entity == null) {
            return null;
        }
        FoodResponseDTO dto = new FoodResponseDTO();
        dto.setFoodId(entity.getFoodId());
        dto.setName(entity.getName());
        dto.setPrice(entity.getPrice());
        dto.setIngredients(entity.getIngredients());
        dto.setRestaurant(restaurant);
        return dto;
    }

    public static Food toEntity(FoodDTO dto) {
        if (dto == null) {
            return null;
        }
        Food entity = new Food();
        entity.setName(dto.getName());
        entity.setPrice(dto.getPrice());
        entity.setIngredients(dto.getIngredients());
        entity.setRestaurantId(dto.getRestaurantId());
        entity.setStatus(dto.getStatus());
        return entity;
    }

    /**
     * Applies only the non-null fields present in the DTO onto the existing entity (partial update).
     */
    public static void applyPartialUpdate(Food entity, FoodDTO dto) {
        if (dto.getName() != null) {
            entity.setName(dto.getName());
        }
        if (dto.getPrice() != null) {
            entity.setPrice(dto.getPrice());
        }
        if (dto.getIngredients() != null) {
            entity.setIngredients(dto.getIngredients());
        }
        if (dto.getRestaurantId() != null) {
            entity.setRestaurantId(dto.getRestaurantId());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
    }
}
