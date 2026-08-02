package fu.se193114.detail.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import fu.se193114.detail.common.OnCreate;
import fu.se193114.detail.common.OnUpdate;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class DetailDTO {

    private Long detailId;

    @NotBlank(message = "name is required", groups = OnCreate.class)
    @Size(max = 100, message = "name must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    private String name;

    @NotNull(message = "price is required", groups = OnCreate.class)
    private Integer price;

    @NotBlank(message = "ingredients is required", groups = OnCreate.class)
    @Size(max = 500, message = "ingredients must be at most 500 characters", groups = {OnCreate.class, OnUpdate.class})
    private String ingredients;

    @NotNull(message = "masterId is required", groups = OnCreate.class)
    private Long masterId;

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private MasterDTO master;

    @Pattern(regexp = "ACTIVE|INACTIVE", message = "status must be one of ACTIVE, INACTIVE",
            groups = {OnCreate.class, OnUpdate.class})
    private String status;
}
