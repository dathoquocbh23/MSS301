package fu.se193114.master.service.impl;

import fu.se193114.master.common.DuplicateNameException;
import fu.se193114.master.common.MasterMapper;
import fu.se193114.master.common.NotFoundException;
import fu.se193114.master.common.ValidationException;
import fu.se193114.master.dto.MasterDTO;
import fu.se193114.master.dto.PageDTO;
import fu.se193114.master.entity.Master;
import fu.se193114.master.repository.CategoryRepository;
import fu.se193114.master.repository.MasterRepository;
import fu.se193114.master.service.MasterService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class MasterServiceImpl implements MasterService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final boolean SIZE_OVER_MAX_IS_ERROR = true;

    private final MasterRepository repository;

    @Autowired
    private CategoryRepository categoryRepository;

    public MasterServiceImpl(MasterRepository repository) {
        this.repository = repository;
    }

    @Override
    public MasterDTO create(MasterDTO dto) {
        log.info("Creating master");

        if (repository.existsByName(dto.getName())) {
            throw new DuplicateNameException("Name is duplicated");
        }
        requireCategoryExists(dto.getCategoryId());

        Master entity = MasterMapper.toEntity(dto);
        entity.setMasterId(null);
        entity.setStatus("ACTIVE");

        return MasterMapper.toDTO(repository.save(entity));
    }

    @Override
    public MasterDTO update(Long masterId, MasterDTO dto) {
        log.info("Updating master id={}", masterId);
        Master entity = findOrThrow(masterId, "Master Id is not found");

        if (dto.getName() != null && repository.existsByNameAndMasterIdNot(dto.getName(), masterId)) {
            throw new DuplicateNameException("Name is duplicated");
        }
        if (dto.getCategoryId() != null) { requireCategoryExists(dto.getCategoryId()); }

        MasterMapper.applyPartialUpdate(entity, dto);
        return MasterMapper.toDTO(repository.save(entity));
    }

    @Override
    public MasterDTO getById(Long masterId) {
        log.info("Getting master id={}", masterId);
        return MasterMapper.toDTO(findOrThrow(masterId, "Master is not found"));
    }

    @Override
    public void deactivate(Long masterId) {
        log.info("Deactivating master id={}", masterId);
        Master entity = findOrThrow(masterId, "Master is not found");
        entity.setStatus("INACTIVE");
        repository.save(entity);
    }

    @Override
    public PageDTO list(Integer page, Integer size, String name, String ownerName) {
        log.info("Listing masters page={} size={} name={} ownerName={}", page, size, name, ownerName);

        int pageNumber = page == null ? 0 : page;
        int pageSize = size == null ? DEFAULT_PAGE_SIZE : size;
        if (pageNumber < 0 || pageSize < 1 || (SIZE_OVER_MAX_IS_ERROR && pageSize > MAX_PAGE_SIZE)) {
            throw new ValidationException("Data validation failed");
        }
        pageSize = Math.min(pageSize, MAX_PAGE_SIZE);

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Master> result = repository.search(blankToNull(name), blankToNull(ownerName), pageable);

        List<MasterDTO> content = new ArrayList<>();
        for (Master entity : result.getContent()) {
            content.add(MasterMapper.toDTO(entity));
        }

        return new PageDTO(result.getSize(), result.getNumber(), result.getTotalPages(),
                result.getTotalElements(), result.isFirst(), result.isLast(), content);
    }

    private Master findOrThrow(Long masterId, String message) {
        return repository.findById(masterId).orElseThrow(() -> new NotFoundException(message));
    }

    private void requireCategoryExists(Long categoryId) {
        if (!categoryRepository.existsById(categoryId)) {
            throw new ValidationException("categoryId is not found");
        }
    }

    private String blankToNull(String value) {
        return value == null || value.trim().isEmpty() ? null : value;
    }
}
