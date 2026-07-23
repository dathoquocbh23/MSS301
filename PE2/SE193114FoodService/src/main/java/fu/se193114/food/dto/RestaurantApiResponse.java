package fu.se193114.food.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class RestaurantApiResponse {

    private int status;
    private String message;
    private RestaurantDTO data;
    private String timestamp;
}
