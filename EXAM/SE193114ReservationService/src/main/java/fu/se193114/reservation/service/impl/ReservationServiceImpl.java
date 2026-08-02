package fu.se193114.reservation.service.impl;

import feign.FeignException;
import fu.se193114.reservation.common.DateOnlySerializer;
import fu.se193114.reservation.common.NotFoundException;
import fu.se193114.reservation.common.ReservationMapper;
import fu.se193114.reservation.common.RoomStatusException;
import fu.se193114.reservation.common.ValidationException;
import fu.se193114.reservation.dto.PageDTO;
import fu.se193114.reservation.dto.ReservationDTO;
import fu.se193114.reservation.dto.ReservationDetailDTO;
import fu.se193114.reservation.dto.RoomApiResponse;
import fu.se193114.reservation.dto.RoomDTO;
import fu.se193114.reservation.entity.Reservation;
import fu.se193114.reservation.repository.ReservationRepository;
import fu.se193114.reservation.repository.RoomClient;
import fu.se193114.reservation.service.ReservationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Slf4j
@Service
public class ReservationServiceImpl implements ReservationService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final boolean SIZE_OVER_MAX_IS_ERROR = true;
    private static final String ROOM_AVAILABLE = "AVAILABLE";
    private static final List<String> ALLOWED_STATUS =
            List.of("CONFIRMED", "CHECKED_IN", "CHECKED_OUT", "CANCELLED");

    private final ReservationRepository repository;
    private final RoomClient roomClient;

    public ReservationServiceImpl(ReservationRepository repository, RoomClient roomClient) {
        this.repository = repository;
        this.roomClient = roomClient;
    }

    @Override
    public ReservationDTO create(ReservationDTO dto) {
        log.info("Creating reservation");

        Long roomId = dto.getRoomId();
        if (roomId == null) {
            throw new ValidationException("roomId is required");
        }

        RoomDTO room = fetchRoomForBooking(roomId);
        requireCheckOutAfterCheckIn(dto.getCheckInDate(), dto.getCheckOutDate());
        requireGuestsWithinCapacity(dto.getNumberOfGuests(), room);

        Reservation entity = ReservationMapper.toEntity(dto);
        entity.setReservationId(null);
        entity.setRoomId(roomId);
        entity.setStatus("CONFIRMED");
        entity.setTotalAmount(computeTotalAmount(room, dto.getCheckInDate(), dto.getCheckOutDate()));

        return ReservationMapper.toDTO(repository.save(entity));
    }

    @Override
    public ReservationDTO update(Long reservationId, ReservationDTO dto) {
        log.info("Updating reservation id={}", reservationId);
        Reservation entity = findOrThrow(reservationId, "Reservation ID is not found");

        if (dto.getRoomId() != null) {
            requireRoomExists(dto.getRoomId());
        }

        ReservationMapper.applyPartialUpdate(entity, dto);
        requireCheckOutAfterCheckIn(entity.getCheckInDate(), entity.getCheckOutDate());

        RoomDTO room = fetchRoomOrNull(entity.getRoomId());
        requireGuestsWithinCapacity(entity.getNumberOfGuests(), room);
        if (room != null) {
            entity.setTotalAmount(computeTotalAmount(room, entity.getCheckInDate(), entity.getCheckOutDate()));
        }

        return ReservationMapper.toDTO(repository.save(entity));
    }

    @Override
    public ReservationDetailDTO getById(Long reservationId) {
        log.info("Getting reservation id={}", reservationId);
        Reservation entity = findOrThrow(reservationId, "Reservation is not found");
        return ReservationMapper.toResponseDTO(entity, fetchRoomOrNull(entity.getRoomId()));
    }

    @Override
    public void cancel(Long reservationId) {
        log.info("Cancelling reservation id={}", reservationId);
        Reservation entity = findOrThrow(reservationId, "Reservation is not found");
        entity.setStatus("CANCELLED");
        repository.save(entity);
    }

    @Override
    public PageDTO list(Integer page, Integer size, String guestName, String status) {
        log.info("Listing reservations page={} size={} guestName={} status={}", page, size, guestName, status);

        int pageNumber = page == null ? 0 : page;
        int pageSize = size == null ? DEFAULT_PAGE_SIZE : size;
        if (pageNumber < 0 || pageSize < 1 || (SIZE_OVER_MAX_IS_ERROR && pageSize > MAX_PAGE_SIZE)) {
            throw new ValidationException("page/size is out of range");
        }
        pageSize = Math.min(pageSize, MAX_PAGE_SIZE);
        if (status != null && !status.trim().isEmpty() && !ALLOWED_STATUS.contains(status)) {
            throw new ValidationException("status is not a valid enum value");
        }

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Reservation> result = repository.search(blankToNull(guestName), blankToNull(status), pageable);

        List<ReservationDetailDTO> content = new ArrayList<>();
        for (Reservation entity : result.getContent()) {
            content.add(ReservationMapper.toResponseDTO(entity, fetchRoomOrNull(entity.getRoomId())));
        }

        return new PageDTO(result.getSize(), result.getNumber(), result.getTotalPages(),
                result.getTotalElements(), result.isFirst(), result.isLast(), content);
    }

    private Reservation findOrThrow(Long reservationId, String message) {
        return repository.findById(reservationId).orElseThrow(() -> new NotFoundException(message));
    }

    private BigDecimal computeTotalAmount(RoomDTO room, Date checkInDate, Date checkOutDate) {
        if (room == null || room.getPricePerNight() == null || checkInDate == null || checkOutDate == null) {
            return BigDecimal.ZERO;
        }
        long nights = nightsBetween(checkInDate, checkOutDate);
        if (nights <= 0) {
            return BigDecimal.ZERO;
        }
        return room.getPricePerNight().multiply(BigDecimal.valueOf(nights));
    }

    private long nightsBetween(Date checkInDate, Date checkOutDate) {
        LocalDate in = DateOnlySerializer.toLocalDate(checkInDate);
        LocalDate out = DateOnlySerializer.toLocalDate(checkOutDate);
        return ChronoUnit.DAYS.between(in, out);
    }

    private void requireCheckOutAfterCheckIn(Date checkInDate, Date checkOutDate) {
        if (checkInDate == null || checkOutDate == null) {
            return;
        }
        if (nightsBetween(checkInDate, checkOutDate) <= 0) {
            throw new ValidationException("checkOutDate must be after checkInDate");
        }
    }

    private void requireGuestsWithinCapacity(Integer numberOfGuests, RoomDTO room) {
        if (numberOfGuests == null || room == null || room.getCapacity() == null) {
            return;
        }
        if (numberOfGuests > room.getCapacity()) {
            throw new ValidationException("numberOfGuests must not exceed the room capacity");
        }
    }

    private RoomDTO fetchRoomForBooking(Long roomId) {
        RoomDTO room = requireRoomExists(roomId);
        if (!ROOM_AVAILABLE.equals(room.getStatus())) {
            throw new RoomStatusException("Room is not AVAILABLE for reservation");
        }
        return room;
    }

    private RoomDTO requireRoomExists(Long roomId) {
        RoomApiResponse response;
        try {
            response = roomClient.getRoomById(roomId);
        } catch (FeignException.NotFound | FeignException.BadRequest ex) {
            throw new NotFoundException("Room ID is not found");
        }
        if (response == null || response.getData() == null) {
            throw new NotFoundException("Room ID is not found");
        }
        return response.getData();
    }

    private RoomDTO fetchRoomOrNull(Long roomId) {
        if (roomId == null) {
            return null;
        }
        try {
            RoomApiResponse response = roomClient.getRoomById(roomId);
            return response == null ? null : response.getData();
        } catch (Exception ex) {
            log.warn("Cannot fetch room id={}: {}", roomId, ex.getMessage());
            return null;
        }
    }

    private String blankToNull(String value) {
        return value == null || value.trim().isEmpty() ? null : value;
    }
}
