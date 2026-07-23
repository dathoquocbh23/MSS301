package fu.se193114.department.controller;

import fu.se193114.department.common.OnCreate;
import fu.se193114.department.common.OnUpdate;
import fu.se193114.department.dto.ApiResponseDTO;
import fu.se193114.department.dto.DepartmentDTO;
import fu.se193114.department.dto.PageDTO;
import fu.se193114.department.service.DepartmentService;
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
@RequestMapping("/api/departments")
public class SE193114DepartmentController {

    private final DepartmentService departmentService;

    public SE193114DepartmentController(DepartmentService departmentService) {
        this.departmentService = departmentService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Validated(OnCreate.class) @RequestBody DepartmentDTO dto) {
        log.info("POST /api/departments code={}", dto.getCode());
        DepartmentDTO created = departmentService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Department is created successfully", created));
    }

    @PutMapping("/{departmentId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable Long departmentId,
                                                 @Validated(OnUpdate.class) @RequestBody DepartmentDTO dto) {
        log.info("PUT /api/departments/{}", departmentId);
        DepartmentDTO updated = departmentService.update(departmentId, dto);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Department is updated successfully", updated));
    }

    @GetMapping("/{departmentId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable Long departmentId) {
        log.info("GET /api/departments/{}", departmentId);
        DepartmentDTO dto = departmentService.getById(departmentId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Department is retrieved successfully", dto));
    }

    @DeleteMapping("/{departmentId}")
    public ResponseEntity<ApiResponseDTO> delete(@PathVariable Long departmentId) {
        log.info("DELETE /api/departments/{}", departmentId);
        departmentService.softDelete(departmentId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Department is deactivated successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(defaultValue = "0") Integer page,
                                               @RequestParam(defaultValue = "10") Integer size,
                                               @RequestParam(required = false) String name,
                                               @RequestParam(required = false) String status) {
        log.info("GET /api/departments page={} size={} name={} status={}", page, size, name, status);
        PageDTO result = departmentService.list(page, size, name, status);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Departments are retrieved successfully", result));
    }
}
