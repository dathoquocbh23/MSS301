package fu.se193114.employee.service.impl;

import feign.FeignException;
import fu.se193114.employee.common.EmployeeMapper;
import fu.se193114.employee.common.NotFoundException;
import fu.se193114.employee.common.ValidationException;
import fu.se193114.employee.dto.DepartmentApiResponse;
import fu.se193114.employee.dto.DepartmentDTO;
import fu.se193114.employee.dto.EmployeeDTO;
import fu.se193114.employee.dto.PageDTO;
import fu.se193114.employee.entity.Employee;
import fu.se193114.employee.repository.DepartmentClient;
import fu.se193114.employee.repository.EmployeeRepository;
import fu.se193114.employee.service.EmployeeService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.regex.Pattern;

@Slf4j
@Service
public class EmployeeServiceImpl implements EmployeeService {

    private static final List<String> VALID_POSITIONS = List.of("Manager", "Developer", "Staff");
    private static final List<String> VALID_STATUSES = List.of("ACTIVE", "LEFT", "RETIRED", "INACTIVE");
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    private final EmployeeRepository employeeRepository;
    private final DepartmentClient departmentClient;

    public EmployeeServiceImpl(EmployeeRepository employeeRepository, DepartmentClient departmentClient) {
        this.employeeRepository = employeeRepository;
        this.departmentClient = departmentClient;
    }

    @Override
    public EmployeeDTO create(EmployeeDTO dto) {
        Long departmentId = resolveDepartmentId(dto);
        log.info("Creating employee email={} departmentId={}", dto.getEmail(), departmentId);
        if (departmentId == null) {
            log.warn("Validation failed creating employee: departmentId is required");
            throw new ValidationException("departmentId is required");
        }
        DepartmentDTO department = fetchDepartmentOrThrow(departmentId);

        Employee entity = EmployeeMapper.toEntity(dto);
        entity.setDepartmentId(departmentId);
        entity.setStatus("ACTIVE");
        entity = employeeRepository.save(entity);

        return EmployeeMapper.toDTO(entity, department);
    }

    @Override
    public EmployeeDTO update(Long employeeId, EmployeeDTO dto) {
        log.info("Updating employee id={}", employeeId);
        Employee entity = employeeRepository.findById(employeeId)
                .orElseThrow(() -> {
                    log.warn("Employee not found id={}", employeeId);
                    return new NotFoundException("Employee is not found");
                });

        validateForUpdate(dto);

        Long departmentId = resolveDepartmentId(dto);
        DepartmentDTO department = null;
        if (departmentId != null) {
            department = fetchDepartmentOrThrow(departmentId);
        }

        EmployeeMapper.applyPartialUpdate(entity, dto);
        if (departmentId != null) {
            entity.setDepartmentId(departmentId);
        }
        entity = employeeRepository.save(entity);

        if (department == null && entity.getDepartmentId() != null) {
            department = fetchDepartmentSafe(entity.getDepartmentId());
        }

        return EmployeeMapper.toDTO(entity, department);
    }

    /**
     * Resolves the effective department id from either the flat {@code departmentId}
     * attribute or the nested {@code department.departmentId} attribute, preferring
     * the flat value when both are present.
     */
    private Long resolveDepartmentId(EmployeeDTO dto) {
        if (dto.getDepartmentId() != null) {
            return dto.getDepartmentId();
        }
        if (dto.getDepartment() != null) {
            return dto.getDepartment().getDepartmentId();
        }
        return null;
    }

    @Override
    public EmployeeDTO getById(Long employeeId) {
        log.info("Fetching employee id={}", employeeId);
        Employee entity = employeeRepository.findById(employeeId)
                .orElseThrow(() -> {
                    log.warn("Employee not found id={}", employeeId);
                    return new NotFoundException("Employee is not found");
                });

        DepartmentDTO department = fetchDepartmentSafe(entity.getDepartmentId());
        return EmployeeMapper.toDTO(entity, department);
    }

    @Override
    public void delete(Long employeeId) {
        log.info("Deactivating employee id={}", employeeId);
        Employee entity = employeeRepository.findById(employeeId)
                .orElseThrow(() -> {
                    log.warn("Employee not found id={}", employeeId);
                    return new NotFoundException("Employee is not found");
                });
        entity.setStatus("INACTIVE");
        employeeRepository.save(entity);
    }

    @Override
    public PageDTO list(int page, int size, String name, String status) {
        log.info("Listing employees page={} size={} name={} status={}", page, size, name, status);
        if (page < 0) {
            log.warn("Validation failed listing employees: page must be >= 0");
            throw new ValidationException("page must be >= 0");
        }
        if (size <= 0 || size > 100) {
            log.warn("Validation failed listing employees: size must be between 1 and 100");
            throw new ValidationException("size must be between 1 and 100");
        }
        if (status != null && !status.isBlank() && !VALID_STATUSES.contains(status)) {
            log.warn("Validation failed listing employees: invalid status={}", status);
            throw new ValidationException("status must be one of ACTIVE, LEFT, RETIRED, INACTIVE");
        }

        String normalizedName = (name == null || name.isBlank()) ? null : name.trim();
        String normalizedStatus = (status == null || status.isBlank()) ? null : status;

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "employeeId"));
        Page<Employee> result = employeeRepository.search(normalizedName, normalizedStatus, pageable);

        List<EmployeeDTO> content = result.getContent().stream()
                .map(e -> EmployeeMapper.toDTO(e, fetchDepartmentSafe(e.getDepartmentId())))
                .toList();

        return new PageDTO(
                result.getSize(),
                result.getNumber(),
                result.getTotalPages(),
                result.getTotalElements(),
                result.isFirst(),
                result.isLast(),
                content
        );
    }

    private DepartmentDTO fetchDepartmentOrThrow(Long departmentId) {
        if (departmentId == null) {
            throw new NotFoundException("Department ID is not found");
        }
        try {
            DepartmentApiResponse response = departmentClient.getDepartmentById(departmentId);
            if (response == null || response.getData() == null) {
                log.warn("Department lookup returned no data departmentId={}", departmentId);
                throw new NotFoundException("Department ID is not found");
            }
            return response.getData();
        } catch (FeignException e) {
            log.warn("Feign department lookup failed departmentId={} message={}", departmentId, e.getMessage());
            throw new NotFoundException("Department ID is not found");
        } catch (NotFoundException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Department lookup failed departmentId={} message={}", departmentId, e.getMessage());
            throw new NotFoundException("Department ID is not found");
        }
    }

    private DepartmentDTO fetchDepartmentSafe(Long departmentId) {
        if (departmentId == null) {
            return null;
        }
        try {
            DepartmentApiResponse response = departmentClient.getDepartmentById(departmentId);
            return response == null ? null : response.getData();
        } catch (Exception e) {
            log.warn("Department lookup failed departmentId={} message={}", departmentId, e.getMessage());
            return null;
        }
    }

    private void validateForUpdate(EmployeeDTO dto) {
        if (dto.getFullName() != null) {
            if (dto.getFullName().isBlank()) {
                log.warn("Validation failed updating employee: fullName is required");
                throw new ValidationException("fullName is required");
            }
            if (dto.getFullName().length() > 100) {
                log.warn("Validation failed updating employee: fullName must be at most 100 characters");
                throw new ValidationException("fullName must be at most 100 characters");
            }
        }
        if (dto.getEmail() != null) {
            if (dto.getEmail().isBlank()) {
                log.warn("Validation failed updating employee: email is required");
                throw new ValidationException("email is required");
            }
            if (dto.getEmail().length() > 100) {
                log.warn("Validation failed updating employee: email must be at most 100 characters");
                throw new ValidationException("email must be at most 100 characters");
            }
            if (!EMAIL_PATTERN.matcher(dto.getEmail()).matches()) {
                log.warn("Validation failed updating employee: email must be a valid email");
                throw new ValidationException("email must be a valid email");
            }
        }
        if (dto.getPosition() != null) {
            if (dto.getPosition().isBlank()) {
                log.warn("Validation failed updating employee: position is required");
                throw new ValidationException("position is required");
            }
            if (dto.getPosition().length() > 30) {
                log.warn("Validation failed updating employee: position must be at most 30 characters");
                throw new ValidationException("position must be at most 30 characters");
            }
            if (!VALID_POSITIONS.contains(dto.getPosition())) {
                log.warn("Validation failed updating employee: invalid position={}", dto.getPosition());
                throw new ValidationException("position must be one of Manager, Developer, Staff");
            }
        }
        if (dto.getStatus() != null && !VALID_STATUSES.contains(dto.getStatus())) {
            log.warn("Validation failed updating employee: invalid status={}", dto.getStatus());
            throw new ValidationException("status must be one of ACTIVE, LEFT, RETIRED, INACTIVE");
        }
    }
}
