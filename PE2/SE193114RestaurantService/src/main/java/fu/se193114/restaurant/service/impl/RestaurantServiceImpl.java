package fu.se193114.restaurant.service.impl;

import fu.se193114.restaurant.common.DuplicateNameException;
import fu.se193114.restaurant.common.NotFoundException;
import fu.se193114.restaurant.common.RestaurantMapper;
import fu.se193114.restaurant.common.ValidationException;
import fu.se193114.restaurant.dto.PageDTO;
import fu.se193114.restaurant.dto.RestaurantDTO;
import fu.se193114.restaurant.entity.Restaurant;
import fu.se193114.restaurant.repository.CategoryRepository;
import fu.se193114.restaurant.repository.RestaurantRepository;
import fu.se193114.restaurant.service.RestaurantService;
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
public class RestaurantServiceImpl implements RestaurantService {

    private static final int MAX_PAGE_SIZE = 100;
    private static final List<String> ALLOWED_STATUS = Arrays.asList("ACTIVE", "INACTIVE");

    private final RestaurantRepository repository;
    private final CategoryRepository categoryRepository;

    public RestaurantServiceImpl(RestaurantRepository repository, CategoryRepository categoryRepository) {
        this.repository = repository;
        this.categoryRepository = categoryRepository;
    }

    @Override
    public RestaurantDTO create(RestaurantDTO dto) {
        log.info("Creating restaurant name={}", dto.getName());
        if (repository.existsByName(dto.getName())) {
            log.warn("Duplicate restaurant name: {}", dto.getName());
            throw new DuplicateNameException("Restaurant name already exists: " + dto.getName());
        }
        if (!categoryRepository.existsById(dto.getCategoryId())) {
            log.warn("Category not found with id: {}", dto.getCategoryId());
            throw new ValidationException("Category not found with id: " + dto.getCategoryId());
        }
        Restaurant entity = RestaurantMapper.toEntity(dto);
        entity.setRestaurantId(null);
        entity.setStatus("ACTIVE");
        Restaurant saved = repository.save(entity);
        return RestaurantMapper.toDTO(saved);
    }

    @Override
    public RestaurantDTO update(Long restaurantId, RestaurantDTO dto) {
        log.info("Updating restaurant id={}", restaurantId);
        Restaurant entity = repository.findById(restaurantId)
                .orElseThrow(() -> {
                    log.warn("Restaurant not found with id: {}", restaurantId);
                    return new NotFoundException("Restaurant not found with id: " + restaurantId);
                });

        if (dto.getName() != null) {
            if (repository.existsByNameAndRestaurantIdNot(dto.getName(), restaurantId)) {
                log.warn("Duplicate restaurant name: {}", dto.getName());
                throw new DuplicateNameException("Restaurant name already exists: " + dto.getName());
            }
            entity.setName(dto.getName());
        }
        if (dto.getCategoryId() != null) {
            if (!categoryRepository.existsById(dto.getCategoryId())) {
                log.warn("Category not found with id: {}", dto.getCategoryId());
                throw new ValidationException("Category not found with id: " + dto.getCategoryId());
            }
            entity.setCategoryId(dto.getCategoryId());
        }
        if (dto.getStatus() != null) {
            if (!ALLOWED_STATUS.contains(dto.getStatus())) {
                log.warn("Invalid status: {}", dto.getStatus());
                throw new ValidationException("status must be one of ACTIVE, INACTIVE");
            }
            entity.setStatus(dto.getStatus());
        }
        if (dto.getOwner() != null) {
            entity.setOwner(dto.getOwner());
        }
        if (dto.getPriceFrom() != null) {
            entity.setPriceFrom(dto.getPriceFrom());
        }
        if (dto.getPriceTo() != null) {
            entity.setPriceTo(dto.getPriceTo());
        }
        if (dto.getPhone() != null) {
            entity.setPhone(dto.getPhone());
        }
        if (dto.getAddress() != null) {
            entity.setAddress(dto.getAddress());
        }
        if (dto.getOpenDate() != null) {
            entity.setOpenDate(dto.getOpenDate());
        }

        Restaurant saved = repository.save(entity);
        return RestaurantMapper.toDTO(saved);
    }

    @Override
    public RestaurantDTO getById(Long restaurantId) {
        log.info("Getting restaurant id={}", restaurantId);
        Restaurant entity = repository.findById(restaurantId)
                .orElseThrow(() -> {
                    log.warn("Restaurant not found with id: {}", restaurantId);
                    return new NotFoundException("Restaurant not found with id: " + restaurantId);
                });
        return RestaurantMapper.toDTO(entity);
    }

    @Override
    public void softDelete(Long restaurantId) {
        log.info("Deactivating restaurant id={}", restaurantId);
        Restaurant entity = repository.findById(restaurantId)
                .orElseThrow(() -> {
                    log.warn("Restaurant not found with id: {}", restaurantId);
                    return new NotFoundException("Restaurant not found with id: " + restaurantId);
                });
        entity.setStatus("INACTIVE");
        repository.save(entity);
    }

    @Override
    public PageDTO list(Integer page, Integer size, String name, String ownerName) {
        log.info("Listing restaurants page={} size={} name={} ownerName={}", page, size, name, ownerName);
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

        String nameFilter = null;
        if (name != null && !name.trim().isEmpty()) {
            nameFilter = name.trim();
        }

        String ownerNameFilter = null;
        if (ownerName != null && !ownerName.trim().isEmpty()) {
            ownerNameFilter = ownerName.trim();
        }

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Restaurant> resultPage = repository.search(nameFilter, ownerNameFilter, pageable);

        List<RestaurantDTO> content = new ArrayList<>();
        for (Restaurant restaurant : resultPage.getContent()) {
            content.add(RestaurantMapper.toDTO(restaurant));
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
