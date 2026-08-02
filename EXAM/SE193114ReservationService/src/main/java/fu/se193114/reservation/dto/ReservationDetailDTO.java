package fu.se193114.reservation.dto;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.reservation.common.DateOnlySerializer;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
public class ReservationDetailDTO {

    private Long reservationId;

    private String guestName;

    private String guestEmail;

    private String guestPhone;

    @JsonSerialize(using = DateOnlySerializer.class)
    private Date checkInDate;

    @JsonSerialize(using = DateOnlySerializer.class)
    private Date checkOutDate;

    private Integer numberOfGuests;

    private BigDecimal totalAmount;

    private String status;

    private RoomDTO room;
}
