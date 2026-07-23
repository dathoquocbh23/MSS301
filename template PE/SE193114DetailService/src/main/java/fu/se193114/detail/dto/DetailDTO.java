package fu.se193114.detail.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

/**
 * DTO phia N. Co ca masterId (phang) va master (nested) — doc de xem
 * endpoint nao tra nested, endpoint nao tra phang (PE1 nested moi cho,
 * PE2 chi nested o list!).
 */
@Getter
@Setter
@NoArgsConstructor
public class DetailDTO {

    private Long detailId;

    @NotBlank(message = "name is required")
    @Size(max = 100, message = "name must be at most 100 characters")
    private String name;

    @Size(max = 100, message = "description must be at most 100 characters")
    private String description;

    @Pattern(regexp = "ACTIVE|INACTIVE", message = "status must be one of ACTIVE, INACTIVE")
    private String status;

    @NotNull(message = "startDate is required")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date startDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date endDate;

    private Long masterId;

    private MasterDTO master;
}
