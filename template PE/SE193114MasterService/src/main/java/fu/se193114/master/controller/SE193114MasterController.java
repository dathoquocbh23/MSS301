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
        log.info("POST /api/masters");
        MasterDTO created = masterService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Master created successfully", created));
    }

    @PutMapping("/{masterId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable Long masterId,
                                                 @Validated(OnUpdate.class) @RequestBody MasterDTO dto) {
        log.info("PUT /api/masters/{}", masterId);
        MasterDTO updated = masterService.update(masterId, dto);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Master updated successfully", updated));
    }

    @GetMapping("/{masterId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable Long masterId) {
        log.info("GET /api/masters/{}", masterId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", masterService.getById(masterId)));
    }

    @DeleteMapping("/{masterId}")
    public ResponseEntity<ApiResponseDTO> deactivate(@PathVariable Long masterId) {
        log.info("DELETE /api/masters/{}", masterId);
        masterService.deactivate(masterId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Master is deactivated successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(required = false) Integer page,
                                               @RequestParam(required = false) Integer size,
                                               @RequestParam(required = false) String name,
                                               @RequestParam(required = false) String ownerName) {
        log.info("GET /api/masters page={} size={} name={} ownerName={}", page, size, name, ownerName);
        PageDTO result = masterService.list(page, size, name, ownerName);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", result));
    }
}
