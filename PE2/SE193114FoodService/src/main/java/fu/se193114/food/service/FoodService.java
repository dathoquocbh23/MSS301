package fu.se193114.food.service;

import fu.se193114.food.dto.FoodDTO;
import fu.se193114.food.dto.FoodListDTO;

public interface FoodService {

    FoodDTO create(FoodDTO dto);

    FoodDTO update(Long foodId, FoodDTO dto);

    FoodDTO getById(Long foodId);

    void delete(Long foodId);

    FoodListDTO list(int page, int size, String name, String ingredients);
}
