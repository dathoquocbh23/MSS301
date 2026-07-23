package fu.se193114.master.controller;

import fu.se193114.master.common.OnCreate;
import fu.se193114.master.common.OnUpdate;
import fu.se193114.master.dto.ApiResponseDTO;
import fu.se193114.master.dto.MasterDTO;
import fu.se193114.master.dto.PageDTO;
import fu.se193114.master.service.MasterService;
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

/**
 * Ten controller + base path + message: COPY Y NGUYEN CAU CHU TRONG DE.
 */
@Slf4j
@RestController
@RequestMapping("/api/masters")
public class SE193114MasterController {

    private final MasterService masterService;

    public SE193114MasterController(MasterService masterService) {
        this.masterService = masterService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Validated(OnCreate.class) @RequestBody MasterDTO dto) {
        log.info("POST /api/masters code={}", dto.getCode());
        MasterDTO created = masterService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Master is created successfully", created));
    }

    @PutMapping("/{masterId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable Long masterId,
                                                 @Validated(OnUpdate.class) @RequestBody MasterDTO dto) {
        log.info("PUT /api/masters/{}", masterId);
        MasterDTO updated = masterService.update(masterId, dto);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Master is updated successfully", updated));
    }

    @GetMapping("/{masterId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable Long masterId) {
        log.info("GET /api/masters/{}", masterId);
        MasterDTO dto = masterService.getById(masterId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Master is retrieved successfully", dto));
    }

    @DeleteMapping("/{masterId}")
    public ResponseEntity<ApiResponseDTO> delete(@PathVariable Long masterId) {
        log.info("DELETE /api/masters/{}", masterId);
        masterService.softDelete(masterId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Master is deactivated successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(defaultValue = "0") Integer page,
                                               @RequestParam(defaultValue = "10") Integer size,
                                               @RequestParam(required = false) String name,
                                               @RequestParam(required = false) String status) {
        log.info("GET /api/masters page={} size={} name={} status={}", page, size, name, status);
        PageDTO result = masterService.list(page, size, name, status);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Masters are retrieved successfully", result));
    }
}
