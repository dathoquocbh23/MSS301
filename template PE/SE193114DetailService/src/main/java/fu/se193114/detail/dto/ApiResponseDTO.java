package fu.se193114.detail.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ApiResponseDTO {

    private int status;

    private String message;

    private Object data;

    private String timestamp;

    public ApiResponseDTO(int status, String message, Object data) {
        this.status = status;
        this.message = message;
        this.data = data;
        this.timestamp = java.time.Instant.now().truncatedTo(java.time.temporal.ChronoUnit.SECONDS).toString();
    }

    public static ApiResponseDTO of(int status, String message, Object data) {
        return new ApiResponseDTO(status, message, data);
    }
}
