package fu.se193114.food.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
public class RestaurantDTO {

    private Long restaurantId;
    private String name;
    private String owner;
    private Integer priceFrom;
    private Integer priceTo;
    private String phone;
    private String address;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date openDate;

    private String status;
    private Long categoryId;
}
