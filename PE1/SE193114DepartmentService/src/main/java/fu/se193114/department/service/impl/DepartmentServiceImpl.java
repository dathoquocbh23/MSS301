package fu.se193114.department.service.impl;

import fu.se193114.department.common.DepartmentMapper;
import fu.se193114.department.common.DuplicateCodeException;
import fu.se193114.department.common.NotFoundException;
import fu.se193114.department.common.ValidationException;
import fu.se193114.department.dto.DepartmentDTO;
import fu.se193114.department.dto.PageDTO;
import fu.se193114.department.entity.Department;
import fu.se193114.department.repository.DepartmentRepository;
import fu.se193114.department.service.DepartmentService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Service
public class DepartmentServiceImpl implements DepartmentService {

    private static final int MAX_PAGE_SIZE = 100;
    private static final List<String> ALLOWED_STATUS = Arrays.asList("ACTIVE", "INACTIVE", "CLOSED");

    private final DepartmentRepository repository;

    public DepartmentServiceImpl(DepartmentRepository repository) {
        this.repository = repository;
    }

    @Override
    public DepartmentDTO create(DepartmentDTO dto) {
        log.info("Creating department code={}", dto.getCode());
        if (repository.existsByCode(dto.getCode())) {
            log.warn("Duplicate department code: {}", dto.getCode());
            throw new DuplicateCodeException("Department code already exists: " + dto.getCode());
        }
        Department entity = DepartmentMapper.toEntity(dto);
        entity.setDepartmentId(null);
        entity.setStatus("ACTIVE");
        Department saved = repository.save(entity);
        return DepartmentMapper.toDTO(saved);
    }

    @Override
    public DepartmentDTO update(Long departmentId, DepartmentDTO dto) {
        log.info("Updating department id={}", departmentId);
        Department entity = repository.findById(departmentId)
                .orElseThrow(() -> {
                    log.warn("Department not found with id: {}", departmentId);
                    return new NotFoundException("Department not found with id: " + departmentId);
                });

        if (dto.getCode() != null) {
            if (repository.existsByCodeAndDepartmentIdNot(dto.getCode(), departmentId)) {
                log.warn("Duplicate department code: {}", dto.getCode());
                throw new DuplicateCodeException("Department code already exists: " + dto.getCode());
            }
            entity.setCode(dto.getCode());
        }
        if (dto.getName() != null) {
            entity.setName(dto.getName());
        }
        if (dto.getLocation() != null) {
            entity.setLocation(dto.getLocation());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
        if (dto.getEffectiveDate() != null) {
            entity.setEffectiveDate(dto.getEffectiveDate());
        }
        if (dto.getParentId() != null) {
            entity.setParentId(dto.getParentId());
        }

        Department saved = repository.save(entity);
        return DepartmentMapper.toDTO(saved);
    }

    @Override
    public DepartmentDTO getById(Long departmentId) {
        log.info("Getting department id={}", departmentId);
        Department entity = repository.findById(departmentId)
                .orElseThrow(() -> {
                    log.warn("Department not found with id: {}", departmentId);
                    return new NotFoundException("Department not found with id: " + departmentId);
                });
        return DepartmentMapper.toDTO(entity);
    }

    @Override
    public void softDelete(Long departmentId) {
        log.info("Deactivating department id={}", departmentId);
        Department entity = repository.findById(departmentId)
                .orElseThrow(() -> {
                    log.warn("Department not found with id: {}", departmentId);
                    return new NotFoundException("Department not found with id: " + departmentId);
                });
        entity.setStatus("INACTIVE");
        repository.save(entity);
    }

    @Override
    public PageDTO list(Integer page, Integer size, String name, String status) {
        log.info("Listing departments page={} size={} name={} status={}", page, size, name, status);
        int pageNumber = page == null ? 0 : page;
        int pageSize = size == null ? 10 : size;

        if (pageNumber < 0) {
            log.warn("Invalid page number: {}", pageNumber);
            throw new ValidationException("page must be greater than or equal to 0");
        }
        if (pageSize < 1) {
            log.warn("Invalid page size: {}", pageSize);
            throw new ValidationException("size must be greater than or equal to 1");
        }
        if (pageSize > MAX_PAGE_SIZE) {
            log.warn("Page size too large: {}", pageSize);
            throw new ValidationException("size must be at most " + MAX_PAGE_SIZE);
        }

        String statusFilter = null;
        if (status != null && !status.trim().isEmpty()) {
            statusFilter = status.trim();
            if (!ALLOWED_STATUS.contains(statusFilter)) {
                log.warn("Invalid status filter: {}", statusFilter);
                throw new ValidationException("status must be one of ACTIVE, INACTIVE, CLOSED");
            }
        }

        String nameFilter = null;
        if (name != null && !name.trim().isEmpty()) {
            nameFilter = name.trim();
        }

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Department> resultPage = repository.search(nameFilter, statusFilter, pageable);

        List<DepartmentDTO> content = new ArrayList<>();
        for (Department department : resultPage.getContent()) {
            content.add(DepartmentMapper.toDTO(department));
        }

        PageDTO pageDTO = new PageDTO();
        pageDTO.setSize(resultPage.getSize());
        pageDTO.setPage(resultPage.getNumber());
        pageDTO.setTotalPages(resultPage.getTotalPages());
        pageDTO.setTotalElements(resultPage.getTotalElements());
        pageDTO.setFirst(resultPage.isFirst());
        pageDTO.setLast(resultPage.isLast());
        pageDTO.setContent(content);
        return pageDTO;
    }
}
