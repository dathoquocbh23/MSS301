package fu.se193114.department.dto;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.department.common.DateOnlyDeserializer;
import fu.se193114.department.common.DateOnlySerializer;
import fu.se193114.department.common.OnCreate;
import fu.se193114.department.common.OnUpdate;
import fu.se193114.department.common.ValidEffectiveDate;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
public class DepartmentDTO {

    private Long departmentId;

    @NotBlank(message = "code is required", groups = OnCreate.class)
    @Size(max = 10, message = "code must be at most 10 characters", groups = {OnCreate.class, OnUpdate.class})
    @Pattern(regexp = "^[A-Za-z0-9]+$", message = "code must match ^[A-Za-z0-9]+$", groups = {OnCreate.class, OnUpdate.class})
    private String code;

    @NotBlank(message = "name is required", groups = OnCreate.class)
    @Size(max = 50, message = "name must be at most 50 characters", groups = {OnCreate.class, OnUpdate.class})
    private String name;

    @Size(max = 100, message = "location must be at most 100 characters", groups = {OnCreate.class, OnUpdate.class})
    private String location;

    @Pattern(regexp = "ACTIVE|INACTIVE|CLOSED", message = "status must be one of ACTIVE, INACTIVE, CLOSED", groups = OnUpdate.class)
    private String status;

    @ValidEffectiveDate(groups = {OnCreate.class, OnUpdate.class})
    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date effectiveDate;

    private Long parentId;
}
