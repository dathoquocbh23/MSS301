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
    private String roomNumber;

    @NotBlank(message = "roomType is required", groups = OnCreate.class)
    @Size(max = 10, message = "roomType must be at most 10 characters", groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = "SINGLE|DOUBLE|SUITE|DELUXE", message = "roomType must be one of SINGLE, DOUBLE, SUITE, DELUXE",
            groups = {OnCreate.class, OnUpdate.class})
    private String roomType;

    @NotNull(message = "pricePerNight is required", groups = OnCreate.class)
    @DecimalMin(value="0.0", inclusive=false, message = "Must be >0")
    private BigDecimal pricePerNight;

    @NotNull(message = "capacity is required", groups = OnCreate.class)
    @Min(1)
    @Max(10)
    private Integer capacity;

    @NotNull(message = "floor is required", groups = OnCreate.class)
    @Min(1)
    private Integer floor;

    @Pattern(regexp = "AVAILABLE|OCCUPIED|MAINTENANCE", message = "status must be one of AVAILABLE, OCCUPIED, MAINTENANCE",
            groups = {OnCreate.class, OnUpdate.class})
    private String status;
}
