package fu.se193114.detail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Boc vo ApiResponseDTO ma MasterService tra ve qua Feign — data nam trong field "data".
 */
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class MasterApiResponse {

    private int status;
    private String message;
    private MasterDTO data;
    private String timestamp;
}
