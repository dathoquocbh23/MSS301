package fu.se193114.food.controller;

import fu.se193114.food.dto.ApiResponseDTO;
import fu.se193114.food.dto.FoodDTO;
import fu.se193114.food.dto.FoodListDTO;
import fu.se193114.food.service.FoodService;
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
@RequestMapping("/api/foods")
public class SE193114FoodController {

    private final FoodService foodService;

    public SE193114FoodController(FoodService foodService) {
        this.foodService = foodService;
    }

    @PostMapping
    public ResponseEntity<ApiResponseDTO> create(@Valid @RequestBody FoodDTO dto) {
        log.info("POST /api/foods requested name={}", dto.getName());
        FoodDTO created = foodService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponseDTO.of(1, "Food created successfully", created));
    }

    @PutMapping("/{foodId}")
    public ResponseEntity<ApiResponseDTO> update(@PathVariable("foodId") Long foodId,
                                                 @RequestBody FoodDTO dto) {
        log.info("PUT /api/foods/{} requested", foodId);
        FoodDTO updated = foodService.update(foodId, dto);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Food updated successfully", updated));
    }

    @GetMapping("/{foodId}")
    public ResponseEntity<ApiResponseDTO> getById(@PathVariable("foodId") Long foodId) {
        log.info("GET /api/foods/{} requested", foodId);
        FoodDTO dto = foodService.getById(foodId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Food retrieved successfully", dto));
    }

    @DeleteMapping("/{foodId}")
    public ResponseEntity<ApiResponseDTO> delete(@PathVariable("foodId") Long foodId) {
        log.info("DELETE /api/foods/{} requested", foodId);
        foodService.delete(foodId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Food deleted successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size,
            @RequestParam(name = "name", required = false) String name,
            @RequestParam(name = "ingredients", required = false) String ingredients) {
        log.info("GET /api/foods requested page={} size={} name={} ingredients={}", page, size, name, ingredients);
        FoodListDTO result = foodService.list(page, size, name, ingredients);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponseDTO.of(1, "Foods retrieved successfully", result));
    }
}
