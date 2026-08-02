package fu.se193114.detail.service.impl;

import feign.FeignException;
import fu.se193114.detail.common.DetailMapper;
import fu.se193114.detail.common.NotFoundException;
import fu.se193114.detail.common.ValidationException;
import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.DetailListDTO;
import fu.se193114.detail.dto.DetailResponseDTO;
import fu.se193114.detail.dto.MasterApiResponse;
import fu.se193114.detail.dto.MasterDTO;
import fu.se193114.detail.entity.Detail;
import fu.se193114.detail.repository.DetailRepository;
import fu.se193114.detail.repository.MasterClient;
import fu.se193114.detail.service.DetailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class DetailServiceImpl implements DetailService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final boolean SIZE_OVER_MAX_IS_ERROR = true;

    private final DetailRepository repository;
    private final MasterClient masterClient;

    public DetailServiceImpl(DetailRepository repository, MasterClient masterClient) {
        this.repository = repository;
        this.masterClient = masterClient;
    }

    @Override
    public DetailDTO create(DetailDTO dto) {
        log.info("Creating detail");

        Long masterId = resolveMasterId(dto);
        if (masterId == null) {
            throw new ValidationException("masterId is required");
        }
        MasterDTO master = fetchMasterOrThrow(masterId);

        Detail entity = DetailMapper.toEntity(dto);
        entity.setDetailId(null);
        entity.setMasterId(masterId);
        entity.setStatus("ACTIVE");

        return DetailMapper.toDTO(repository.save(entity), master);
    }

    @Override
    public DetailDTO update(Long detailId, DetailDTO dto) {
        log.info("Updating detail id={}", detailId);
        Detail entity = findOrThrow(detailId, "Detail Id is not found");

        Long masterId = resolveMasterId(dto);
        if (masterId != null) {
            fetchMasterOrThrow(masterId);
        }

        DetailMapper.applyPartialUpdate(entity, dto);
        if (masterId != null) {
            entity.setMasterId(masterId);
        }
        Detail saved = repository.save(entity);
        return DetailMapper.toDTO(saved, fetchMasterOrNull(saved.getMasterId()));
    }

    @Override
    public DetailDTO getById(Long detailId) {
        log.info("Getting detail id={}", detailId);
        Detail entity = findOrThrow(detailId, "Detail is not found");
        return DetailMapper.toDTO(entity, fetchMasterOrNull(entity.getMasterId()));
    }

    @Override
    public void deactivate(Long detailId) {
        log.info("Deactivating detail id={}", detailId);
        Detail entity = findOrThrow(detailId, "Detail is not found");
        entity.setStatus("INACTIVE");
        repository.save(entity);
    }

    @Override
    public DetailListDTO list(Integer page, Integer size, String name, String ingredients) {
        log.info("Listing details page={} size={} name={} ingredients={}", page, size, name, ingredients);

        int pageNumber = page == null ? 0 : page;
        int pageSize = size == null ? DEFAULT_PAGE_SIZE : size;
        if (pageNumber < 0 || pageSize < 1 || (SIZE_OVER_MAX_IS_ERROR && pageSize > MAX_PAGE_SIZE)) {
            throw new ValidationException("Data validation failed");
        }
        pageSize = Math.min(pageSize, MAX_PAGE_SIZE);

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Detail> result = repository.search(blankToNull(name), blankToNull(ingredients), pageable);

        List<DetailResponseDTO> content = new ArrayList<>();
        for (Detail entity : result.getContent()) {
            content.add(DetailMapper.toResponseDTO(entity, fetchMasterOrNull(entity.getMasterId())));
        }

        return new DetailListDTO(result.getSize(), result.getNumber(), result.getTotalPages(),
                result.isFirst(), result.isLast(), content);
    }

    private Detail findOrThrow(Long detailId, String message) {
        return repository.findById(detailId).orElseThrow(() -> new NotFoundException(message));
    }

    private Long resolveMasterId(DetailDTO dto) {
        if (dto.getMasterId() != null) {
            return dto.getMasterId();
        }
        if (dto.getMaster() != null) {
            return dto.getMaster().getMasterId();
        }
        return null;
    }

    private MasterDTO fetchMasterOrThrow(Long masterId) {
        try {
            MasterApiResponse response = masterClient.getMasterById(masterId);
            if (response == null || response.getData() == null) {
                throw new NotFoundException("Master Id is not found");
            }
            return response.getData();
        } catch (FeignException.NotFound | FeignException.BadRequest ex) {
            throw new NotFoundException("Master Id is not found");
        }
    }

    private MasterDTO fetchMasterOrNull(Long masterId) {
        if (masterId == null) {
            return null;
        }
        try {
            MasterApiResponse response = masterClient.getMasterById(masterId);
            return response == null ? null : response.getData();
        } catch (Exception ex) {
            log.warn("Cannot fetch master id={}: {}", masterId, ex.getMessage());
            return null;
        }
    }

    private String blankToNull(String value) {
        return value == null || value.trim().isEmpty() ? null : value;
    }
}
