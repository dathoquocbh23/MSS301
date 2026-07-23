package fu.se193114.food.service.impl;

import feign.FeignException;
import fu.se193114.food.common.FoodMapper;
import fu.se193114.food.common.NotFoundException;
import fu.se193114.food.common.ValidationException;
import fu.se193114.food.dto.FoodDTO;
import fu.se193114.food.dto.FoodListDTO;
import fu.se193114.food.dto.FoodResponseDTO;
import fu.se193114.food.dto.RestaurantApiResponse;
import fu.se193114.food.dto.RestaurantDTO;
import fu.se193114.food.entity.Food;
import fu.se193114.food.repository.FoodRepository;
import fu.se193114.food.repository.RestaurantClient;
import fu.se193114.food.service.FoodService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class FoodServiceImpl implements FoodService {

    private static final List<String> VALID_STATUSES = List.of("ACTIVE", "INACTIVE");

    private final FoodRepository foodRepository;
    private final RestaurantClient restaurantClient;

    public FoodServiceImpl(FoodRepository foodRepository, RestaurantClient restaurantClient) {
        this.foodRepository = foodRepository;
        this.restaurantClient = restaurantClient;
    }

    @Override
    public FoodDTO create(FoodDTO dto) {
        Long restaurantId = dto.getRestaurantId();
        log.info("Creating food name={} restaurantId={}", dto.getName(), restaurantId);
        if (restaurantId == null) {
            log.warn("Validation failed creating food: restaurantId is required");
            throw new ValidationException("restaurantId is required");
        }
        fetchRestaurantOrThrow(restaurantId);

        Food entity = FoodMapper.toEntity(dto);
        entity.setRestaurantId(restaurantId);
        entity.setStatus("ACTIVE");
        entity = foodRepository.save(entity);

        return FoodMapper.toDTO(entity);
    }

    @Override
    public FoodDTO update(Long foodId, FoodDTO dto) {
        log.info("Updating food id={}", foodId);
        Food entity = foodRepository.findById(foodId)
                .orElseThrow(() -> {
                    log.warn("Food not found id={}", foodId);
                    return new NotFoundException("Food is not found");
                });

        validateForUpdate(dto);

        if (dto.getRestaurantId() != null) {
            fetchRestaurantOrThrow(dto.getRestaurantId());
        }

        FoodMapper.applyPartialUpdate(entity, dto);
        entity = foodRepository.save(entity);

        return FoodMapper.toDTO(entity);
    }

    @Override
    public FoodDTO getById(Long foodId) {
        log.info("Fetching food id={}", foodId);
        Food entity = foodRepository.findById(foodId)
                .orElseThrow(() -> {
                    log.warn("Food not found id={}", foodId);
                    return new NotFoundException("Food is not found");
                });

        return FoodMapper.toDTO(entity);
    }

    @Override
    public void delete(Long foodId) {
        log.info("Deactivating food id={}", foodId);
        Food entity = foodRepository.findById(foodId)
                .orElseThrow(() -> {
                    log.warn("Food not found id={}", foodId);
                    return new NotFoundException("Food is not found");
                });
        entity.setStatus("INACTIVE");
        foodRepository.save(entity);
    }

    @Override
    public FoodListDTO list(int page, int size, String name, String ingredients) {
        log.info("Listing foods page={} size={} name={} ingredients={}", page, size, name, ingredients);
        if (page < 0) {
            log.warn("Validation failed listing foods: page must be >= 0");
            throw new ValidationException("page must be >= 0");
        }
        if (size <= 0 || size > 100) {
            log.warn("Validation failed listing foods: size must be between 1 and 100");
            throw new ValidationException("size must be between 1 and 100");
        }

        String normalizedName = (name == null || name.isBlank()) ? null : name.trim();
        String normalizedIngredients = (ingredients == null || ingredients.isBlank()) ? null : ingredients.trim();

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "foodId"));
        Page<Food> result = foodRepository.search(normalizedName, normalizedIngredients, pageable);

        List<FoodResponseDTO> foods = result.getContent().stream()
                .map(f -> FoodMapper.toResponseDTO(f, fetchRestaurantSafe(f.getRestaurantId())))
                .toList();

        return new FoodListDTO(
                result.getSize(),
                result.getNumber(),
                result.getTotalPages(),
                result.isFirst(),
                result.isLast(),
                foods
        );
    }

    private RestaurantDTO fetchRestaurantOrThrow(Long restaurantId) {
        if (restaurantId == null) {
            throw new NotFoundException("Restaurant ID is not found");
        }
        try {
            RestaurantApiResponse response = restaurantClient.getRestaurantById(restaurantId);
            if (response == null || response.getData() == null) {
                log.warn("Restaurant lookup returned no data restaurantId={}", restaurantId);
                throw new NotFoundException("Restaurant ID is not found");
            }
            return response.getData();
        } catch (FeignException e) {
            log.warn("Feign restaurant lookup failed restaurantId={} message={}", restaurantId, e.getMessage());
            throw new NotFoundException("Restaurant ID is not found");
        } catch (NotFoundException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Restaurant lookup failed restaurantId={} message={}", restaurantId, e.getMessage());
            throw new NotFoundException("Restaurant ID is not found");
        }
    }

    private RestaurantDTO fetchRestaurantSafe(Long restaurantId) {
        if (restaurantId == null) {
            return null;
        }
        try {
            RestaurantApiResponse response = restaurantClient.getRestaurantById(restaurantId);
            return response == null ? null : response.getData();
        } catch (Exception e) {
            log.warn("Restaurant lookup failed restaurantId={} message={}", restaurantId, e.getMessage());
            return null;
        }
    }

    private void validateForUpdate(FoodDTO dto) {
        if (dto.getName() != null) {
            if (dto.getName().isBlank()) {
                log.warn("Validation failed updating food: name is required");
                throw new ValidationException("name is required");
            }
            if (dto.getName().length() > 100) {
                log.warn("Validation failed updating food: name must be at most 100 characters");
                throw new ValidationException("name must be at most 100 characters");
            }
        }
        if (dto.getIngredients() != null) {
            if (dto.getIngredients().isBlank()) {
                log.warn("Validation failed updating food: ingredients is required");
                throw new ValidationException("ingredients is required");
            }
            if (dto.getIngredients().length() > 500) {
                log.warn("Validation failed updating food: ingredients must be at most 500 characters");
                throw new ValidationException("ingredients must be at most 500 characters");
            }
        }
        if (dto.getStatus() != null && !VALID_STATUSES.contains(dto.getStatus())) {
            log.warn("Validation failed updating food: invalid status={}", dto.getStatus());
            throw new ValidationException("status must be one of ACTIVE, INACTIVE");
        }
    }
}
