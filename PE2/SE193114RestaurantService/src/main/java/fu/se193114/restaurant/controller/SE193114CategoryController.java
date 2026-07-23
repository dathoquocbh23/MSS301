package fu.se193114.restaurant.controller;

import fu.se193114.restaurant.dto.ApiResponseDTO;
import fu.se193114.restaurant.dto.PageDTO;
import fu.se193114.restaurant.service.CategoryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/api/categories")
public class SE193114CategoryController {

    private final CategoryService categoryService;

    public SE193114CategoryController(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    @GetMapping
    public ResponseEntity<ApiResponseDTO> list(@RequestParam(defaultValue = "0") Integer page,
                                               @RequestParam(defaultValue = "10") Integer size) {
        log.info("GET /api/categories page={} size={}", page, size);
        PageDTO result = categoryService.list(page, size);
        return ResponseEntity.ok(ApiResponseDTO.of(1, "Categories are retrieved successfully", result));
    }
}
