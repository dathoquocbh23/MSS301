package fu.se193114.reservation.common;

import fu.se193114.reservation.dto.ReservationDTO;
import fu.se193114.reservation.dto.ReservationDetailDTO;
import fu.se193114.reservation.dto.RoomDTO;
import fu.se193114.reservation.entity.Reservation;

public final class ReservationMapper {

    private ReservationMapper() {
    }

    public static ReservationDTO toDTO(Reservation entity) {
        if (entity == null) {
            return null;
        }
        ReservationDTO dto = new ReservationDTO();
        dto.setReservationId(entity.getReservationId());
        dto.setGuestName(entity.getGuestName());
        dto.setGuestEmail(entity.getGuestEmail());
        dto.setGuestPhone(entity.getGuestPhone());
        dto.setCheckInDate(entity.getCheckInDate());
        dto.setCheckOutDate(entity.getCheckOutDate());
        dto.setNumberOfGuests(entity.getNumberOfGuests());
        dto.setTotalAmount(entity.getTotalAmount());
        dto.setStatus(entity.getStatus());
        dto.setRoomId(entity.getRoomId());
        return dto;
    }

    public static ReservationDTO toDTO(Reservation entity, RoomDTO room) {
        ReservationDTO dto = toDTO(entity);

        return dto;
    }

    public static ReservationDetailDTO toResponseDTO(Reservation entity, RoomDTO room) {
        if (entity == null) {
            return null;
        }
        ReservationDetailDTO dto = new ReservationDetailDTO();
        dto.setReservationId(entity.getReservationId());
        dto.setGuestName(entity.getGuestName());
        dto.setGuestEmail(entity.getGuestEmail());
        dto.setGuestPhone(entity.getGuestPhone());
        dto.setCheckInDate(entity.getCheckInDate());
        dto.setCheckOutDate(entity.getCheckOutDate());
        dto.setNumberOfGuests(entity.getNumberOfGuests());
        dto.setTotalAmount(entity.getTotalAmount());
        dto.setRoom(room);
        return dto;
    }

    public static Reservation toEntity(ReservationDTO dto) {
        if (dto == null) {
            return null;
        }
        Reservation entity = new Reservation();
        entity.setGuestName(dto.getGuestName());
        entity.setGuestEmail(dto.getGuestEmail());
        entity.setGuestPhone(dto.getGuestPhone());
        entity.setCheckInDate(dto.getCheckInDate());
        entity.setCheckOutDate(dto.getCheckOutDate());
        entity.setNumberOfGuests(dto.getNumberOfGuests());
        entity.setTotalAmount(dto.getTotalAmount());
        entity.setStatus(dto.getStatus());
        entity.setRoomId(dto.getRoomId());
        return entity;
    }

    public static void applyPartialUpdate(Reservation entity, ReservationDTO dto) {
        if (dto.getGuestName() != null) {
            entity.setGuestName(dto.getGuestName());
        }
        if (dto.getGuestEmail() != null) {
            entity.setGuestEmail(dto.getGuestEmail());
        }
        if (dto.getGuestPhone() != null) {
            entity.setGuestPhone(dto.getGuestPhone());
        }
        if (dto.getCheckInDate() != null) {
            entity.setCheckInDate(dto.getCheckInDate());
        }
        if (dto.getCheckOutDate() != null) {
            entity.setCheckOutDate(dto.getCheckOutDate());
        }
        if (dto.getNumberOfGuests() != null) {
            entity.setNumberOfGuests(dto.getNumberOfGuests());
        }
        if (dto.getTotalAmount() != null) {
            entity.setTotalAmount(dto.getTotalAmount());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
        if (dto.getRoomId() != null) {
            entity.setRoomId(dto.getRoomId());
        }
    }
}
