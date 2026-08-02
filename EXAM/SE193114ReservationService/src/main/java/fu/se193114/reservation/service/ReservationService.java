package fu.se193114.reservation.service;

import fu.se193114.reservation.dto.PageDTO;
import fu.se193114.reservation.dto.ReservationDTO;
import fu.se193114.reservation.dto.ReservationDetailDTO;

public interface ReservationService {

    ReservationDTO create(ReservationDTO dto);

    ReservationDTO update(Long reservationId, ReservationDTO dto);

    ReservationDetailDTO getById(Long reservationId);

    void cancel(Long reservationId);

    PageDTO list(Integer page, Integer size, String guestName, String status);
}
