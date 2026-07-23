package fu.se193114.restaurant.controller;

import fu.se193114.restaurant.common.OnCreate;
import fu.se193114.restaurant.common.OnUpdate;
import fu.se193114.restaurant.dto.ApiResponseDTO;
import fu.se193114.restaurant.dto.PageDTO;
import fu.se193114.restaurant.dto.RestaurantDTO;
import fu.se193114.restaurant.service.RestaurantService;
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
@RequestMapping("/api/restaurants")
public class SE193114RestaurantController {

    private final RestaurantService restaurantService;

    public SE193114RestaurantController(RestaurantService restaurantService) {
        this.restaurantService = restaurantService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Validated(OnCreate.class) @RequestBody RestaurantDTO dto) {
        log.info("POST /api/restaurants name={}", dto.getName());
        RestaurantDTO created = restaurantService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Restaurant is created successfully", created));
    }

    @PutMapping("/{restaurantId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable Long restaurantId,
                                                 @Validated(OnUpdate.class) @RequestBody RestaurantDTO dto) {
        log.info("PUT /api/restaurants/{}", restaurantId);
        RestaurantDTO updated = restaurantService.update(restaurantId, dto);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Restaurant is updated successfully", updated));
    }

    @GetMapping("/{restaurantId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable Long restaurantId) {
        log.info("GET /api/restaurants/{}", restaurantId);
        RestaurantDTO dto = restaurantService.getById(restaurantId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Restaurant is retrieved successfully", dto));
    }

    @DeleteMapping("/{restaurantId}")
    public ResponseEntity<ApiResponseDTO> delete(@PathVariable Long restaurantId) {
        log.info("DELETE /api/restaurants/{}", restaurantId);
        restaurantService.softDelete(restaurantId);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Restaurant is deactivated successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(defaultValue = "0") Integer page,
                                               @RequestParam(defaultValue = "10") Integer size,
                                               @RequestParam(required = false) String name,
                                               @RequestParam(required = false) String ownerName) {
        log.info("GET /api/restaurants page={} size={} name={} ownerName={}", page, size, name, ownerName);
        PageDTO result = restaurantService.list(page, size, name, ownerName);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Restaurants are retrieved successfully", result));
    }
}
