package fu.se193114.room.service.impl;

import fu.se193114.room.common.DuplicateNameException;
import fu.se193114.room.common.RoomMapper;
import fu.se193114.room.common.NotFoundException;
import fu.se193114.room.common.ValidationException;
import fu.se193114.room.dto.RoomDTO;
import fu.se193114.room.dto.PageDTO;
import fu.se193114.room.entity.Room;
import fu.se193114.room.repository.RoomRepository;
import fu.se193114.room.service.RoomService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class RoomServiceImpl implements RoomService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final boolean SIZE_OVER_MAX_IS_ERROR = true;
    private static final java.util.List<String> ALLOWED_STATUS = java.util.List.of("AVAILABLE", "OCCUPIED", "MAINTENANCE");

    private final RoomRepository repository;

    public RoomServiceImpl(RoomRepository repository) {
        this.repository = repository;
    }

    @Override
    public RoomDTO create(RoomDTO dto) {
        log.info("Creating room");

        if (repository.existsByRoomNumber(dto.getRoomNumber())) {
            throw new DuplicateNameException("Room number is duplicated");
        }

        Room entity = RoomMapper.toEntity(dto);
        entity.setRoomId(null);
        entity.setStatus("AVAILABLE");

        return RoomMapper.toDTO(repository.save(entity));
    }

    @Override
    public RoomDTO update(Long roomId, RoomDTO dto) {
        log.info("Updating room id={}", roomId);
        Room entity = findOrThrow(roomId, "Room Id is not found");

        if (dto.getRoomNumber() != null && repository.existsByRoomNumberAndRoomIdNot(dto.getRoomNumber(), roomId)) {
            throw new DuplicateNameException("Room number is duplicated");
        }

        RoomMapper.applyPartialUpdate(entity, dto);
        return RoomMapper.toDTO(repository.save(entity));
    }

    @Override
    public RoomDTO getById(Long roomId) {
        log.info("Getting room id={}", roomId);
        return RoomMapper.toDTO(findOrThrow(roomId, "Room is not found"));
    }

    @Override
    public void deactivate(Long roomId) {
        log.info("Deactivating room id={}", roomId);
        Room entity = findOrThrow(roomId, "Room is not found");
        entity.setStatus("MAINTENANCE");
        repository.save(entity);
    }

    @Override
    public PageDTO list(Integer page, Integer size, String roomType, String status) {
        log.info("Listing rooms page={} size={} roomType={} status={}", page, size, roomType, status);

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
        Page<Room> result = repository.search(blankToNull(roomType), blankToNull(status), pageable);

        List<RoomDTO> content = new ArrayList<>();
        for (Room entity : result.getContent()) {
            content.add(RoomMapper.toDTO(entity));
        }

        return new PageDTO(result.getSize(), result.getNumber(), result.getTotalPages(),
                result.getTotalElements(), result.isFirst(), result.isLast(), content);
    }

    private Room findOrThrow(Long roomId, String message) {
        return repository.findById(roomId).orElseThrow(() -> new NotFoundException(message));
    }

    private String blankToNull(String value) {
        return value == null || value.trim().isEmpty() ? null : value;
    }
}
