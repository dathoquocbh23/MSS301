package fu.se193114.room.controller;

import fu.se193114.room.common.OnCreate;
import fu.se193114.room.common.OnUpdate;
import fu.se193114.room.dto.ApiResponseDTO;
import fu.se193114.room.dto.RoomDTO;
import fu.se193114.room.dto.PageDTO;
import fu.se193114.room.service.RoomService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/api/rooms")
public class SE193114RoomController {

    private final RoomService roomService;

    public SE193114RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Validated(OnCreate.class) @RequestBody RoomDTO dto) {
        log.info("POST /api/rooms");
        RoomDTO created = roomService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Room created successfully", created));
    }

    @PutMapping("/{roomId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable Long roomId,
                                                 @Validated(OnUpdate.class) @RequestBody RoomDTO dto) {
        log.info("PUT /api/rooms/{}", roomId);
        RoomDTO updated = roomService.update(roomId, dto);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Room updated successfully", updated));
    }

    @GetMapping("/{roomId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable Long roomId) {
        log.info("GET /api/rooms/{}", roomId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", roomService.getById(roomId)));
    }

    @DeleteMapping("/{roomId}")
    public ResponseEntity<ApiResponseDTO> deactivate(@PathVariable Long roomId) {
        log.info("DELETE /api/rooms/{}", roomId);
        roomService.deactivate(roomId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Room set to MAINTENANCE successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(required = false) Integer page,
                                               @RequestParam(required = false) Integer size,
                                               @RequestParam(required = false) String roomType,
                                               @RequestParam(required = false) String status) {
        log.info("GET /api/rooms page={} size={} roomType={} status={}", page, size, roomType, status);
        PageDTO result = roomService.list(page, size, roomType, status);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", result));
    }
}
