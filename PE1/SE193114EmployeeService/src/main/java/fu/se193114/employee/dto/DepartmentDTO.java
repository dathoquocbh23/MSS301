package fu.se193114.employee.dto;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.employee.common.DateOnlyDeserializer;
import fu.se193114.employee.common.DateOnlySerializer;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
public class DepartmentDTO {

    private Long departmentId;
    private String code;
    private String name;
    private String location;
    private String status;

    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date effectiveDate;

    private Long parentId;
}
