package fu.se193114.detail.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class DetailResponseDTO {

    private Long detailId;

    private String name;

    private Integer price;

    private String ingredients;

    private MasterDTO master;
}
