package fu.se193114.reservation.service.impl;

import feign.FeignException;
import fu.se193114.reservation.common.ReservationMapper;
import fu.se193114.reservation.common.NotFoundException;
import fu.se193114.reservation.common.RoomStatusException;
import fu.se193114.reservation.common.ValidationException;
import fu.se193114.reservation.dto.ReservationDTO;
import fu.se193114.reservation.dto.ReservationListDTO;
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
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class ReservationServiceImpl implements ReservationService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final boolean SIZE_OVER_MAX_IS_ERROR = true;
    private static final java.util.List<String> ALLOWED_STATUS = java.util.List.of("CONFIRMED", "CHECKED_IN", "CHECKED_OUT", "CANCELLED");

    private final ReservationRepository repository;
    private final RoomClient roomClient;

    public ReservationServiceImpl(ReservationRepository repository, RoomClient roomClient) {
        this.repository = repository;
        this.roomClient = roomClient;
    }

    @Override
    public ReservationDTO create(ReservationDTO dto) {
        log.info("Creating reservation");

        Long roomId = resolveRoomId(dto);
        if (roomId == null) {
            throw new ValidationException("roomId is required");
        }
        RoomDTO room = fetchRoomOrThrow(roomId);
        int number = dto.getCheckOutDate().getDay() - dto.getCheckInDate().getDay();
        int total = number * room.getPricePerNight().intValue();
        dto.setTotalAmount(BigDecimal.valueOf(number));
        Reservation entity = ReservationMapper.toEntity(dto);
        entity.setReservationId(null);
        entity.setRoomId(roomId);
        entity.setStatus("CONFIRMED");

        return ReservationMapper.toDTO(repository.save(entity), room);
    }

    @Override
    public ReservationDTO update(Long reservationId, ReservationDTO dto) {
        log.info("Updating reservation id={}", reservationId);
        Reservation entity = findOrThrow(reservationId, "Reservation Id is not found");

        Long roomId = resolveRoomId(dto);
        if (roomId != null) {
            fetchRoomOrThrow(roomId);
        }

        ReservationMapper.applyPartialUpdate(entity, dto);
        if (roomId != null) {
            entity.setRoomId(roomId);
        }
        Reservation saved = repository.save(entity);
        return ReservationMapper.toDTO(saved, fetchRoomOrNull(saved.getRoomId()));
    }

    @Override
    public ReservationDTO getById(Long reservationId) {
        log.info("Getting reservation id={}", reservationId);
        Reservation entity = findOrThrow(reservationId, "Reservation is not found");
        return ReservationMapper.toDTO(entity, fetchRoomOrNull(entity.getRoomId()));
    }

    @Override
    public void deactivate(Long reservationId) {
        log.info("Deactivating reservation id={}", reservationId);
        Reservation entity = findOrThrow(reservationId, "Reservation is not found");
        entity.setStatus("CANCELLED");
        repository.save(entity);
    }

    @Override
    public ReservationListDTO list(Integer page, Integer size, String guestName, String status) {
        log.info("Listing reservations page={} size={} guestName={} status={}", page, size, guestName, status);

        int pageNumber = page == null ? 0 : page;
        int pageSize = size == null ? DEFAULT_PAGE_SIZE : size;
        if (pageNumber < 0 || pageSize < 1 || (SIZE_OVER_MAX_IS_ERROR && pageSize > MAX_PAGE_SIZE)) {
            throw new ValidationException("Data validation failed");
        }
        pageSize = Math.min(pageSize, MAX_PAGE_SIZE);
        if (status != null && !status.trim().isEmpty() && !ALLOWED_STATUS.contains(status)) {
            throw new ValidationException("Data validation failed");
        }

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Reservation> result = repository.search(blankToNull(guestName), blankToNull(status), pageable);

        List<ReservationDetailDTO> content = new ArrayList<>();
        for (Reservation entity : result.getContent()) {
            content.add(ReservationMapper.toResponseDTO(entity, fetchRoomOrNull(entity.getRoomId())));
        }

        return new ReservationListDTO(result.getSize(), result.getNumber(), result.getTotalPages(),
                result.isFirst(), result.isLast(), content);
    }

    private Reservation findOrThrow(Long reservationId, String message) {
        return repository.findById(reservationId).orElseThrow(() -> new NotFoundException(message));
    }

    private Long resolveRoomId(ReservationDTO dto) {
        if (dto.getRoomId() != null) {
            return dto.getRoomId();
        }

        return null;
    }

    private RoomDTO fetchRoomOrThrow(Long roomId) {
        try {
            RoomApiResponse response = roomClient.getRoomById(roomId);
            if (response == null || response.getData() == null) {
                throw new NotFoundException("Room Id is not found");
            }
            if(!response.getData().getStatus().equals("AVAILABLE")) {
                throw new RoomStatusException("Room is not AVAILABLE for reservation");
            }
            return response.getData();
        } catch (FeignException.NotFound | FeignException.BadRequest ex) {
            throw new NotFoundException("Room Id is not found");
        }
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
