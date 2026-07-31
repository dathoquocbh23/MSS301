package fu.se193114.reservation.service;

import fu.se193114.reservation.dto.ReservationDTO;
import fu.se193114.reservation.dto.ReservationListDTO;

public interface ReservationService {

    ReservationDTO create(ReservationDTO dto);

    ReservationDTO update(Long reservationId, ReservationDTO dto);

    ReservationDTO getById(Long reservationId);

    void deactivate(Long reservationId);

    ReservationListDTO list(Integer page, Integer size, String guestName, String status);
}
