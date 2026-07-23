package fu.se193114.detail.service.impl;

import feign.FeignException;
import fu.se193114.detail.common.DetailMapper;
import fu.se193114.detail.common.NotFoundException;
import fu.se193114.detail.common.ValidationException;
import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.MasterApiResponse;
import fu.se193114.detail.dto.MasterDTO;
import fu.se193114.detail.dto.PageDTO;
import fu.se193114.detail.entity.Detail;
import fu.se193114.detail.repository.DetailRepository;
import fu.se193114.detail.repository.MasterClient;
import fu.se193114.detail.service.DetailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class DetailServiceImpl implements DetailService {

    // Enum THEO DE — moi de moi khac!
    private static final List<String> VALID_STATUSES = List.of("ACTIVE", "INACTIVE");

    private final DetailRepository detailRepository;
    private final MasterClient masterClient;

    public DetailServiceImpl(DetailRepository detailRepository, MasterClient masterClient) {
        this.detailRepository = detailRepository;
        this.masterClient = masterClient;
    }

    @Override
    public DetailDTO create(DetailDTO dto) {
        Long masterId = resolveMasterId(dto);
        log.info("Creating detail name={} masterId={}", dto.getName(), masterId);
        if (masterId == null) {
            throw new ValidationException("masterId is required");
        }
        // Feign verify: masterId phai ton tai ben MasterService
        MasterDTO master = fetchMasterOrThrow(masterId);

        Detail entity = DetailMapper.toEntity(dto);
        entity.setMasterId(masterId);
        entity.setStatus("ACTIVE");
        entity = detailRepository.save(entity);

        return DetailMapper.toDTO(entity, master);
    }

    @Override
    public DetailDTO update(Long detailId, DetailDTO dto) {
        log.info("Updating detail id={}", detailId);
        Detail entity = detailRepository.findById(detailId)
                .orElseThrow(() -> {
                    log.warn("Detail not found id={}", detailId);
                    return new NotFoundException("Detail is not found");
                });

        validateForUpdate(dto);

        Long masterId = resolveMasterId(dto);
        MasterDTO master = null;
        if (masterId != null) {
            master = fetchMasterOrThrow(masterId);
        }

        DetailMapper.applyPartialUpdate(entity, dto);
        if (masterId != null) {
            entity.setMasterId(masterId);
        }
        entity = detailRepository.save(entity);

        if (master == null && entity.getMasterId() != null) {
            master = fetchMasterSafe(entity.getMasterId());
        }

        return DetailMapper.toDTO(entity, master);
    }

    /**
     * Lay masterId tu field phang (masterId) hoac tu object nested (master.masterId),
     * uu tien field phang.
     */
    private Long resolveMasterId(DetailDTO dto) {
        if (dto.getMasterId() != null) {
            return dto.getMasterId();
        }
        if (dto.getMaster() != null) {
            return dto.getMaster().getMasterId();
        }
        return null;
    }

    @Override
    public DetailDTO getById(Long detailId) {
        log.info("Fetching detail id={}", detailId);
        Detail entity = detailRepository.findById(detailId)
                .orElseThrow(() -> {
                    log.warn("Detail not found id={}", detailId);
                    return new NotFoundException("Detail is not found");
                });

        MasterDTO master = fetchMasterSafe(entity.getMasterId());
        return DetailMapper.toDTO(entity, master);
    }

    @Override
    public void delete(Long detailId) {
        log.info("Deactivating detail id={}", detailId);
        Detail entity = detailRepository.findById(detailId)
                .orElseThrow(() -> {
                    log.warn("Detail not found id={}", detailId);
                    return new NotFoundException("Detail is not found");
                });
        // Soft delete — doc de xem yeu cau xoa that hay doi status
        entity.setStatus("INACTIVE");
        detailRepository.save(entity);
    }

    @Override
    public PageDTO list(int page, int size, String name, String status) {
        log.info("Listing details page={} size={} name={} status={}", page, size, name, status);
        if (page < 0) {
            throw new ValidationException("page must be >= 0");
        }
        if (size <= 0 || size > 100) {
            throw new ValidationException("size must be between 1 and 100");
        }
        if (status != null && !status.isBlank() && !VALID_STATUSES.contains(status)) {
            throw new ValidationException("status must be one of ACTIVE, INACTIVE");
        }

        String normalizedName = (name == null || name.isBlank()) ? null : name.trim();
        String normalizedStatus = (status == null || status.isBlank()) ? null : status;

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "detailId"));
        Page<Detail> result = detailRepository.search(normalizedName, normalizedStatus, pageable);

        // Nested master cho tung row (Feign per row) — doc de: co de chi can masterId phang!
        List<DetailDTO> content = result.getContent().stream()
                .map(d -> DetailMapper.toDTO(d, fetchMasterSafe(d.getMasterId())))
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

    /**
     * Dung cho create/update: master khong ton tai -> nem loi (message THEO DE).
     */
    private MasterDTO fetchMasterOrThrow(Long masterId) {
        if (masterId == null) {
            throw new NotFoundException("Master ID is not found");
        }
        try {
            MasterApiResponse response = masterClient.getMasterById(masterId);
            if (response == null || response.getData() == null) {
                log.warn("Master lookup returned no data masterId={}", masterId);
                throw new NotFoundException("Master ID is not found");
            }
            return response.getData();
        } catch (FeignException e) {
            log.warn("Feign master lookup failed masterId={} message={}", masterId, e.getMessage());
            throw new NotFoundException("Master ID is not found");
        } catch (NotFoundException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Master lookup failed masterId={} message={}", masterId, e.getMessage());
            throw new NotFoundException("Master ID is not found");
        }
    }

    /**
     * Dung cho get/list: loi Feign thi tra null (khong lam gay response chinh).
     */
    private MasterDTO fetchMasterSafe(Long masterId) {
        if (masterId == null) {
            return null;
        }
        try {
            MasterApiResponse response = masterClient.getMasterById(masterId);
            return response == null ? null : response.getData();
        } catch (Exception e) {
            log.warn("Master lookup failed masterId={} message={}", masterId, e.getMessage());
            return null;
        }
    }

    /**
     * Validate tay cho partial update (vi @Valid tren body update se bat buoc
     * ca field client khong gui). Sua rule + message THEO DE.
     */
    private void validateForUpdate(DetailDTO dto) {
        if (dto.getName() != null) {
            if (dto.getName().isBlank()) {
                throw new ValidationException("name is required");
            }
            if (dto.getName().length() > 100) {
                throw new ValidationException("name must be at most 100 characters");
            }
        }
        if (dto.getDescription() != null && dto.getDescription().length() > 100) {
            throw new ValidationException("description must be at most 100 characters");
        }
        if (dto.getStatus() != null && !VALID_STATUSES.contains(dto.getStatus())) {
            throw new ValidationException("status must be one of ACTIVE, INACTIVE");
        }
    }
}
