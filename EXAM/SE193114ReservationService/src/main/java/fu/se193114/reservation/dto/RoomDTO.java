package fu.se193114.reservation.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class RoomDTO {

    private Long roomId;

    private String roomNumber;

    private String roomType;

    private BigDecimal pricePerNight;

    private Integer capacity;

    private Integer floor;

    private String status;
}
