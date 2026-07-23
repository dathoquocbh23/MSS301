package fu.se193114.department.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Getter
@Setter
public class ApiResponseDTO {

    private int status;
    private String message;
    private Object data;
    private String timestamp;

    public ApiResponseDTO() {
    }

    public ApiResponseDTO(int status, String message, Object data) {
        this.status = status;
        this.message = message;
        this.data = data;
        // Truncated to seconds so the value always reads YYYY-MM-DDThh:mm:ssZ; a raw
        // Instant would append fractional seconds whenever the nano field is non-zero.
        this.timestamp = Instant.now().truncatedTo(ChronoUnit.SECONDS).toString();
    }

    public static ApiResponseDTO of(int status, String message, Object data) {
        return new ApiResponseDTO(status, message, data);
    }
}
