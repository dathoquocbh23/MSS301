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
    @Pattern(regexp = ".*\\S.*", message = "guestName must not be blank", groups = OnUpdate.class)
    private String guestName;

    @NotBlank(message = "guestEmail is required", groups = OnCreate.class)
    @Size(max = 100, message = "guestEmail must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    @Email(message = "guestEmail is invalid", groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = ".*\\S.*", message = "guestEmail must not be blank", groups = OnUpdate.class)
    private String guestEmail;

    @NotBlank(message = "guestPhone is required", groups = OnCreate.class)
    @Size(max = 20, message = "guestPhone must be at most 20 characters", groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = ".*\\S.*", message = "guestPhone must not be blank", groups = OnUpdate.class)
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
    @Min(value = 1, message = "numberOfGuests must be between 1 and 10", groups = {OnCreate.class, OnUpdate.class})
    @Max(value = 10, message = "numberOfGuests must be between 1 and 10", groups = {OnCreate.class, OnUpdate.class})
    private Integer numberOfGuests;

    @DecimalMin(value = "0.0", message = "totalAmount must be greater than or equal to 0",
            groups = {OnCreate.class, OnUpdate.class})
    @Digits(integer = 16, fraction = 2, message = "totalAmount must have at most 16 integer digits and 2 decimal digits",
            groups = {OnCreate.class, OnUpdate.class})
    private BigDecimal totalAmount;

    @Pattern(regexp = "CONFIRMED|CHECKED_IN|CHECKED_OUT|CANCELLED", message = "status must be one of CONFIRMED, CHECKED_IN, CHECKED_OUT, CANCELLED",
            groups = {OnCreate.class, OnUpdate.class})
    private String status;

    @NotNull(message = "roomId is required", groups = OnCreate.class)
    private Long roomId;

}
