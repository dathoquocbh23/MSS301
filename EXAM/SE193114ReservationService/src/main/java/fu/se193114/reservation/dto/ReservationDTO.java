package fu.se193114.reservation.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.reservation.common.DateOnlyDeserializer;
import fu.se193114.reservation.common.DateOnlySerializer;
import fu.se193114.reservation.common.OnCreate;
import fu.se193114.reservation.common.OnUpdate;
import fu.se193114.reservation.common.ValidDate;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
public class ReservationDTO {

    private Long reservationId;

    @NotBlank(message = "guestName is required", groups = OnCreate.class)
    @Size(max = 100, message = "guestName must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    private String guestName;

    @NotBlank(message = "guestEmail is required", groups = OnCreate.class)
    @Size(max = 100, message = "guestEmail must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    @Email(message = "email is invalid", groups = {OnCreate.class, OnUpdate.class})
    private String guestEmail;

    @NotBlank(message = "guestPhone is required", groups = OnCreate.class)
    @Size(max = 20, message = "guestPhone must be at most 20 characters", groups = {OnCreate.class, OnUpdate.class})
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

    @NotNull(message = "roomId is required", groups = OnCreate.class)
    private Long roomId;

}
