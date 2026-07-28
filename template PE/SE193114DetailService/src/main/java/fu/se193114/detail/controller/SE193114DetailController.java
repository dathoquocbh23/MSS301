package fu.se193114.detail.controller;

import fu.se193114.detail.common.OnCreate;
import fu.se193114.detail.common.OnUpdate;
import fu.se193114.detail.dto.ApiResponseDTO;
import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.DetailListDTO;
import fu.se193114.detail.service.DetailService;
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
@RequestMapping("/api/details")
public class SE193114DetailController {

    private final DetailService detailService;

    public SE193114DetailController(DetailService detailService) {
        this.detailService = detailService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Validated(OnCreate.class) @RequestBody DetailDTO dto) {
        log.info("POST /api/details");
        DetailDTO created = detailService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Detail created successfully", created));
    }

    @PutMapping("/{detailId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable Long detailId,
                                                 @Validated(OnUpdate.class) @RequestBody DetailDTO dto) {
        log.info("PUT /api/details/{}", detailId);
        DetailDTO updated = detailService.update(detailId, dto);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Detail updated successfully", updated));
    }

    @GetMapping("/{detailId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable Long detailId) {
        log.info("GET /api/details/{}", detailId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", detailService.getById(detailId)));
    }

    @DeleteMapping("/{detailId}")
    public ResponseEntity<ApiResponseDTO> deactivate(@PathVariable Long detailId) {
        log.info("DELETE /api/details/{}", detailId);
        detailService.deactivate(detailId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Detail is deactivated successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(required = false) Integer page,
                                               @RequestParam(required = false) Integer size,
                                               @RequestParam(required = false) String name,
                                               @RequestParam(required = false) String ingredients) {
        log.info("GET /api/details page={} size={} name={} ingredients={}", page, size, name, ingredients);
        DetailListDTO result = detailService.list(page, size, name, ingredients);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Successful", result));
    }
}
