package fu.se193114.employee.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponseDTO {

    private int status;
    private String message;
    private Object data;
    private String timestamp;

    public static ApiResponseDTO of(int status, String message, Object data) {
        // Truncated to seconds so the value always reads YYYY-MM-DDThh:mm:ssZ; a raw
        // Instant would append fractional seconds whenever the nano field is non-zero.
        String ts = Instant.now().truncatedTo(ChronoUnit.SECONDS).toString();
        return new ApiResponseDTO(status, message, data, ts);
    }
}
