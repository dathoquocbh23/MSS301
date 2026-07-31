package fu.se193114.reservation.controller;

import fu.se193114.reservation.common.OnCreate;
import fu.se193114.reservation.common.OnUpdate;
import fu.se193114.reservation.dto.ApiResponseDTO;
import fu.se193114.reservation.dto.PageDTO;
import fu.se193114.reservation.dto.ReservationDTO;
import fu.se193114.reservation.service.ReservationService;
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
@RequestMapping("/api/reservations")
public class SE193114ReservationController {

    private final ReservationService reservationService;

    public SE193114ReservationController(ReservationService reservationService) {
        this.reservationService = reservationService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Validated(OnCreate.class) @RequestBody ReservationDTO dto) {
        log.info("POST /api/reservations");
        ReservationDTO created = reservationService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Reservation created successfully", created));
    }

    @PutMapping("/{reservationId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable Long reservationId,
                                                 @Validated(OnUpdate.class) @RequestBody ReservationDTO dto) {
        log.info("PUT /api/reservations/{}", reservationId);
        ReservationDTO updated = reservationService.update(reservationId, dto);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Reservation updated successfully", updated));
    }

    @GetMapping("/{reservationId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable Long reservationId) {
        log.info("GET /api/reservations/{}", reservationId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", reservationService.getById(reservationId)));
    }

    @DeleteMapping("/{reservationId}")
    public ResponseEntity<ApiResponseDTO> cancel(@PathVariable Long reservationId) {
        log.info("DELETE /api/reservations/{}", reservationId);
        reservationService.cancel(reservationId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Reservation cancelled successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(required = false) Integer page,
                                               @RequestParam(required = false) Integer size,
                                               @RequestParam(required = false) String guestName,
                                               @RequestParam(required = false) String status) {
        log.info("GET /api/reservations page={} size={} guestName={} status={}", page, size, guestName, status);
        PageDTO result = reservationService.list(page, size, guestName, status);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", result));
    }
}
