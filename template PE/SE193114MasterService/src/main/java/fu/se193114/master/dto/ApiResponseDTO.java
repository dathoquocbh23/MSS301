package fu.se193114.master.dto;

import lombok.Getter;
import lombok.Setter;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

/**
 * Vo response chung theo de. Bang status thuong gap (DOC LAI DE!):
 * 1 = success, 2 = validation error, 3 = duplicate, 4 = not found, 0 = internal error.
 */
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
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
        sdf.setTimeZone(TimeZone.getTimeZone("UTC"));
        this.timestamp = sdf.format(new Date());
    }

    public static ApiResponseDTO of(int status, String message, Object data) {
        return new ApiResponseDTO(status, message, data);
    }
}
