package fu.se193114.employee.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class DepartmentApiResponse {

    private int status;
    private String message;
    private DepartmentDTO data;
    private String timestamp;
}
