package fu.se193114.food.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class FoodDTO {

    private Long foodId;

    @NotBlank(message = "name is required")
    @Size(max = 100, message = "name must be at most 100 characters")
    private String name;

    @NotNull(message = "price is required")
    private Integer price;

    @NotBlank(message = "ingredients is required")
    @Size(max = 500, message = "ingredients must be at most 500 characters")
    private String ingredients;

    private Long restaurantId;

    @Pattern(regexp = "ACTIVE|INACTIVE", message = "status must be one of ACTIVE, INACTIVE")
    private String status;
}
