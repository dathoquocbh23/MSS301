package fu.se193114.reservation.dto;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.reservation.common.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
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

    @NotNull(message = "checkInDate is required", groups = OnCreate.class)
    @ValidDate(groups = {OnCreate.class, OnUpdate.class})
    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date checkInDate;

    @NotNull(message = "checkOutDate is required", groups = OnCreate.class)
    @ValidDate(groups = {OnCreate.class, OnUpdate.class})
    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date checkOutDate;

    @NotNull(message = "numberOfGuests is required", groups = OnCreate.class)
    @Min(1)
    @Max(10)
    private Integer numberOfGuests;

    @NotNull(message = "totalAmount is required", groups = OnCreate.class)
    private BigDecimal totalAmount;

    @Pattern(regexp = "CONFIRMED|CHECKED_IN|CHECKED_OUT|CANCELLED", message = "status must be one of CONFIRMED, CHECKED_IN, CHECKED_OUT, CANCELLED",
            groups = {OnCreate.class, OnUpdate.class})
    private String status;

    private RoomDTO room;
}
