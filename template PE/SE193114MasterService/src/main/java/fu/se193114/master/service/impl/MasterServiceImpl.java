package fu.se193114.master.service.impl;

import fu.se193114.master.common.DuplicateCodeException;
import fu.se193114.master.common.MasterMapper;
import fu.se193114.master.common.NotFoundException;
import fu.se193114.master.common.ValidationException;
import fu.se193114.master.dto.MasterDTO;
import fu.se193114.master.dto.PageDTO;
import fu.se193114.master.entity.Master;
import fu.se193114.master.repository.MasterRepository;
import fu.se193114.master.service.MasterService;
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
public class MasterServiceImpl implements MasterService {

    private static final int MAX_PAGE_SIZE = 100;
    // Enum status THEO DE (moi de moi khac!)
    private static final List<String> ALLOWED_STATUS = Arrays.asList("ACTIVE", "INACTIVE", "CLOSED");

    private final MasterRepository repository;

    public MasterServiceImpl(MasterRepository repository) {
        this.repository = repository;
    }

    @Override
    public MasterDTO create(MasterDTO dto) {
        log.info("Creating master code={}", dto.getCode());
        if (repository.existsByCode(dto.getCode())) {
            log.warn("Duplicate master code: {}", dto.getCode());
            throw new DuplicateCodeException("Master code already exists: " + dto.getCode());
        }
        Master entity = MasterMapper.toEntity(dto);
        entity.setMasterId(null);
        entity.setStatus("ACTIVE");
        Master saved = repository.save(entity);
        return MasterMapper.toDTO(saved);
    }

    @Override
    public MasterDTO update(Long masterId, MasterDTO dto) {
        log.info("Updating master id={}", masterId);
        Master entity = repository.findById(masterId)
                .orElseThrow(() -> {
                    log.warn("Master not found with id: {}", masterId);
                    return new NotFoundException("Master not found with id: " + masterId);
                });

        // Partial update: chi ghi de field nao client gui len (non-null)
        if (dto.getCode() != null) {
            if (repository.existsByCodeAndMasterIdNot(dto.getCode(), masterId)) {
                log.warn("Duplicate master code: {}", dto.getCode());
                throw new DuplicateCodeException("Master code already exists: " + dto.getCode());
            }
            entity.setCode(dto.getCode());
        }
        if (dto.getName() != null) {
            entity.setName(dto.getName());
        }
        if (dto.getDescription() != null) {
            entity.setDescription(dto.getDescription());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
        if (dto.getEffectiveDate() != null) {
            entity.setEffectiveDate(dto.getEffectiveDate());
        }

        Master saved = repository.save(entity);
        return MasterMapper.toDTO(saved);
    }

    @Override
    public MasterDTO getById(Long masterId) {
        log.info("Getting master id={}", masterId);
        Master entity = repository.findById(masterId)
                .orElseThrow(() -> {
                    log.warn("Master not found with id: {}", masterId);
                    return new NotFoundException("Master not found with id: " + masterId);
                });
        return MasterMapper.toDTO(entity);
    }

    @Override
    public void softDelete(Long masterId) {
        log.info("Deactivating master id={}", masterId);
        Master entity = repository.findById(masterId)
                .orElseThrow(() -> {
                    log.warn("Master not found with id: {}", masterId);
                    return new NotFoundException("Master not found with id: " + masterId);
                });
        // Soft delete: doi status, KHONG xoa row (doc de xem yeu cau gi)
        entity.setStatus("INACTIVE");
        repository.save(entity);
    }

    @Override
    public PageDTO list(Integer page, Integer size, String name, String status) {
        log.info("Listing masters page={} size={} name={} status={}", page, size, name, status);
        int pageNumber = page == null ? 0 : page;
        int pageSize = size == null ? 10 : size;

        if (pageNumber < 0) {
            throw new ValidationException("page must be greater than or equal to 0");
        }
        if (pageSize < 1) {
            throw new ValidationException("size must be greater than or equal to 1");
        }
        if (pageSize > MAX_PAGE_SIZE) {
            throw new ValidationException("size must be at most " + MAX_PAGE_SIZE);
        }

        String statusFilter = null;
        if (status != null && !status.trim().isEmpty()) {
            statusFilter = status.trim();
            if (!ALLOWED_STATUS.contains(statusFilter)) {
                throw new ValidationException("status must be one of ACTIVE, INACTIVE, CLOSED");
            }
        }

        String nameFilter = null;
        if (name != null && !name.trim().isEmpty()) {
            nameFilter = name.trim();
        }

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Master> resultPage = repository.search(nameFilter, statusFilter, pageable);

        List<MasterDTO> content = new ArrayList<>();
        for (Master master : resultPage.getContent()) {
            content.add(MasterMapper.toDTO(master));
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
