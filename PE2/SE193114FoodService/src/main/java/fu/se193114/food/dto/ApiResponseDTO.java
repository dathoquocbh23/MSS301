package fu.se193114.food.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

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
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
        sdf.setTimeZone(TimeZone.getTimeZone("UTC"));
        String ts = sdf.format(new Date());
        return new ApiResponseDTO(status, message, data, ts);
    }
}
