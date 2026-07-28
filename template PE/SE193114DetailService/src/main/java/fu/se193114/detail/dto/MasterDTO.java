package fu.se193114.detail.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import fu.se193114.detail.common.DateOnlyDeserializer;
import fu.se193114.detail.common.DateOnlySerializer;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class MasterDTO {

    private Long masterId;

    private String name;

    private String owner;

    private Integer priceFrom;

    private Integer priceTo;

    private String phone;

    private String address;

    @JsonSerialize(using = DateOnlySerializer.class)
    @JsonDeserialize(using = DateOnlyDeserializer.class)
    private Date openDate;

    private String status;
}
