package fu.se193114.master.dto;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.master.common.DateOnlyDeserializer;
import fu.se193114.master.common.DateOnlySerializer;
import fu.se193114.master.common.OnCreate;
import fu.se193114.master.common.OnUpdate;
import fu.se193114.master.common.ValidDate;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
public class MasterDTO {

    private Long masterId;

    @NotBlank(message = "name is required", groups = OnCreate.class)
    @Size(max = 100, message = "name must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    private String name;

    @NotBlank(message = "owner is required", groups = OnCreate.class)
    @Size(max = 100, message = "owner must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    private String owner;

    private Integer priceFrom;

    private Integer priceTo;

    @NotBlank(message = "phone is required", groups = OnCreate.class)
    @Size(max = 11, message = "phone must be at most 11 characters", groups = {OnCreate.class, OnUpdate.class})
    private String phone;

    @NotBlank(message = "address is required", groups = OnCreate.class)
    @Size(max = 100, message = "address must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    private String address;

    @NotNull(message = "openDate is required", groups = OnCreate.class)
    @ValidDate(groups = {OnCreate.class, OnUpdate.class})
    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date openDate;

    @Pattern(regexp = "ACTIVE|INACTIVE", message = "status must be one of ACTIVE, INACTIVE",
            groups = {OnCreate.class, OnUpdate.class})
    private String status;

    @NotNull(message = "categoryId is required", groups = OnCreate.class)
    private Long categoryId;
}
