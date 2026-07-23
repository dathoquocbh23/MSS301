package fu.se193114.employee.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.employee.common.DateOnlyDeserializer;
import fu.se193114.employee.common.DateOnlySerializer;
import jakarta.validation.constraints.Email;
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
public class EmployeeDTO {

    private Long employeeId;

    @NotBlank(message = "fullName is required")
    @Size(max = 100, message = "fullName must be at most 100 characters")
    private String fullName;

    @NotBlank(message = "email is required")
    @Size(max = 100, message = "email must be at most 100 characters")
    @Email(message = "email must be a valid email")
    private String email;

    @NotBlank(message = "position is required")
    @Size(max = 30, message = "position must be at most 30 characters")
    @Pattern(regexp = "Manager|Developer|Staff", message = "position must be one of Manager, Developer, Staff")
    private String position;

    @Pattern(regexp = "ACTIVE|LEFT|RETIRED|INACTIVE", message = "status must be one of ACTIVE, LEFT, RETIRED, INACTIVE")
    private String status;

    @NotNull(message = "startDate is required")
    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date startDate;

    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date endDate;

    /**
     * Not part of the EmployeeDTO specification, which carries the department only as a
     * nested DepartmentDTO. Kept write-only so a request may still supply the id flatly,
     * while the response stays limited to the specified attributes.
     */
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private Long departmentId;

    private DepartmentDTO department;
}
