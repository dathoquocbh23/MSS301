package fu.se193114.employee.controller;

import fu.se193114.employee.dto.ApiResponseDTO;
import fu.se193114.employee.dto.EmployeeDTO;
import fu.se193114.employee.dto.PageDTO;
import fu.se193114.employee.service.EmployeeService;
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

@Slf4j
@RestController
@RequestMapping("/api/employees")
public class SE193114EmployeeController {

    private final EmployeeService employeeService;

    public SE193114EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Valid @RequestBody EmployeeDTO dto) {
        log.info("POST /api/employees requested email={}", dto.getEmail());
        EmployeeDTO created = employeeService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Employee created successfully", created));
    }

    @PutMapping("/{employeeId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable("employeeId") Long employeeId,
                                                 @RequestBody EmployeeDTO dto) {
        log.info("PUT /api/employees/{} requested", employeeId);
        EmployeeDTO updated = employeeService.update(employeeId, dto);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Employee updated successfully", updated));
    }

    @GetMapping("/{employeeId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable("employeeId") Long employeeId) {
        log.info("GET /api/employees/{} requested", employeeId);
        EmployeeDTO dto = employeeService.getById(employeeId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Employee retrieved successfully", dto));
    }

    @DeleteMapping("/{employeeId}")
    public ResponseEntity<ApiResponseDTO> delete(@PathVariable("employeeId") Long employeeId) {
        log.info("DELETE /api/employees/{} requested", employeeId);
        employeeService.delete(employeeId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Employee deleted successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size,
            @RequestParam(name = "name", required = false) String name,
            @RequestParam(name = "status", required = false) String status) {
        log.info("GET /api/employees requested page={} size={} name={} status={}", page, size, name, status);
        PageDTO result = employeeService.list(page, size, name, status);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Employees retrieved successfully", result));
    }
}
