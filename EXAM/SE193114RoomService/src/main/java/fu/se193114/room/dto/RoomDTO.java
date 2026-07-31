package fu.se193114.room.dto;

import fu.se193114.room.common.OnCreate;
import fu.se193114.room.common.OnUpdate;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
public class RoomDTO {

    private Long roomId;

    @NotBlank(message = "roomNumber is required", groups = OnCreate.class)
    @Size(max = 20, message = "roomNumber must be at most 20 characters", groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = ".*\\S.*", message = "roomNumber must not be blank", groups = OnUpdate.class)
    private String roomNumber;

    @NotBlank(message = "roomType is required", groups = OnCreate.class)
    @Size(max = 10, message = "roomType must be at most 10 characters", groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = "SINGLE|DOUBLE|SUITE|DELUXE", message = "roomType must be one of SINGLE, DOUBLE, SUITE, DELUXE",
            groups = {OnCreate.class, OnUpdate.class})
    private String roomType;

    @NotNull(message = "pricePerNight is required", groups = OnCreate.class)
    @DecimalMin(value = "0.0", inclusive = false, message = "pricePerNight must be greater than 0",
            groups = {OnCreate.class, OnUpdate.class})
    @Digits(integer = 16, fraction = 2, message = "pricePerNight must have at most 16 integer digits and 2 decimal digits",
            groups = {OnCreate.class, OnUpdate.class})
    private BigDecimal pricePerNight;

    @NotNull(message = "capacity is required", groups = OnCreate.class)
    @Min(value = 1, message = "capacity must be between 1 and 10", groups = {OnCreate.class, OnUpdate.class})
    @Max(value = 10, message = "capacity must be between 1 and 10", groups = {OnCreate.class, OnUpdate.class})
    private Integer capacity;

    @NotNull(message = "floor is required", groups = OnCreate.class)
    @Min(value = 1, message = "floor must be greater than or equal to 1", groups = {OnCreate.class, OnUpdate.class})
    private Integer floor;

    @Pattern(regexp = "AVAILABLE|OCCUPIED|MAINTENANCE", message = "status must be one of AVAILABLE, OCCUPIED, MAINTENANCE",
            groups = {OnCreate.class, OnUpdate.class})
    private String status;
}
