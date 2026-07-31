package fu.se193114.reservation.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ReservationListDTO {

    private int pageSize;

    private int pageNo;

    private int totalPages;

    private boolean first;

    private boolean last;

    private List<ReservationDetailDTO> reservations;
}
