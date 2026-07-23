package fu.se193114.detail.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

/**
 * Ban copy DTO cua MasterService (moi service tu dinh nghia DTO rieng —
 * khong share code giua 2 project). Chi can cac field ma response can hien thi.
 */
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class MasterDTO {

    private Long masterId;
    private String code;
    private String name;
    private String description;
    private String status;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date effectiveDate;
}
