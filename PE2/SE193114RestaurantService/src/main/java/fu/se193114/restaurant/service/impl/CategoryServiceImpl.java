package fu.se193114.restaurant.service.impl;

import fu.se193114.restaurant.common.CategoryMapper;
import fu.se193114.restaurant.common.ValidationException;
import fu.se193114.restaurant.dto.CategoryDTO;
import fu.se193114.restaurant.dto.PageDTO;
import fu.se193114.restaurant.entity.Category;
import fu.se193114.restaurant.repository.CategoryRepository;
import fu.se193114.restaurant.service.CategoryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class CategoryServiceImpl implements CategoryService {

    private static final int MAX_PAGE_SIZE = 100;

    private final CategoryRepository repository;

    public CategoryServiceImpl(CategoryRepository repository) {
        this.repository = repository;
    }

    @Override
    public PageDTO list(Integer page, Integer size) {
        log.info("Listing categories page={} size={}", page, size);
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

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Category> resultPage = repository.findAll(pageable);

        List<CategoryDTO> content = new ArrayList<>();
        for (Category category : resultPage.getContent()) {
            content.add(CategoryMapper.toDTO(category));
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
