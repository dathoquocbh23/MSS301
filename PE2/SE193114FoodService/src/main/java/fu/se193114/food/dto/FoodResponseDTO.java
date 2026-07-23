package fu.se193114.food.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class FoodResponseDTO {

    private Long foodId;
    private String name;
    private Integer price;
    private String ingredients;
    private RestaurantDTO restaurant;
}
