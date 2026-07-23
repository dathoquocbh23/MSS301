package fu.se193114.master.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import fu.se193114.master.common.OnCreate;
import fu.se193114.master.common.OnUpdate;
import fu.se193114.master.common.ValidEffectiveDate;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

/**
 * Validation THEO DE: message loi copy y nguyen cau chu trong de.
 * OnCreate = field bat buoc khi POST; OnUpdate = chi check format khi PUT (partial update).
 */
@Getter
@Setter
@NoArgsConstructor
public class MasterDTO {

    private Long masterId;

    @NotBlank(message = "code is required", groups = OnCreate.class)
    @Size(max = 10, message = "code must be at most 10 characters", groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = "^[A-Za-z0-9]+$", message = "code must match ^[A-Za-z0-9]+$", groups = {OnCreate.class, OnUpdate.class})
    private String code;

    @NotBlank(message = "name is required", groups = OnCreate.class)
    @Size(max = 50, message = "name must be at most 50 characters", groups = {OnCreate.class, OnUpdate.class})
    private String name;

    @Size(max = 100, message = "description must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    private String description;

    @Pattern(regexp = "ACTIVE|INACTIVE|CLOSED", message = "status must be one of ACTIVE, INACTIVE, CLOSED", groups = OnUpdate.class)
    private String status;

    @ValidEffectiveDate(groups = {OnCreate.class, OnUpdate.class})
    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date effectiveDate;
}
