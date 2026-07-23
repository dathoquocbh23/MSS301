package fu.se193114.detail.controller;

import fu.se193114.detail.dto.ApiResponseDTO;
import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.PageDTO;
import fu.se193114.detail.service.DetailService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Ten controller + base path + message: COPY Y NGUYEN CAU CHU TRONG DE.
 */
@Slf4j
@RestController
@RequestMapping("/api/details")
public class SE193114DetailController {

    private final DetailService detailService;

    public SE193114DetailController(DetailService detailService) {
        this.detailService = detailService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Valid @RequestBody DetailDTO dto) {
        log.info("POST /api/details requested name={}", dto.getName());
        DetailDTO created = detailService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Detail created successfully", created));
    }

    @PutMapping("/{detailId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable("detailId") Long detailId,
                                                 @RequestBody DetailDTO dto) {
        log.info("PUT /api/details/{} requested", detailId);
        DetailDTO updated = detailService.update(detailId, dto);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Detail updated successfully", updated));
    }

    @GetMapping("/{detailId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable("detailId") Long detailId) {
        log.info("GET /api/details/{} requested", detailId);
        DetailDTO dto = detailService.getById(detailId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Detail retrieved successfully", dto));
    }

    @DeleteMapping("/{detailId}")
    public ResponseEntity<ApiResponseDTO> delete(@PathVariable("detailId") Long detailId) {
        log.info("DELETE /api/details/{} requested", detailId);
        detailService.delete(detailId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Detail deleted successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size,
            @RequestParam(name = "name", required = false) String name,
            @RequestParam(name = "status", required = false) String status) {
        log.info("GET /api/details requested page={} size={} name={} status={}", page, size, name, status);
        PageDTO result = detailService.list(page, size, name, status);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Details retrieved successfully", result));
    }
}
