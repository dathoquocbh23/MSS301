package fu.se193114.master.service.impl;

import fu.se193114.master.common.CategoryMapper;
import fu.se193114.master.common.ValidationException;
import fu.se193114.master.dto.CategoryDTO;
import fu.se193114.master.dto.PageDTO;
import fu.se193114.master.entity.Category;
import fu.se193114.master.repository.CategoryRepository;
import fu.se193114.master.service.CategoryService;
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

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;

    private final CategoryRepository repository;

    public CategoryServiceImpl(CategoryRepository repository) {
        this.repository = repository;
    }

    @Override
    public PageDTO list(Integer page, Integer size) {
        log.info("Listing categories page={} size={}", page, size);

        int pageNumber = page == null ? 0 : page;
        int pageSize = size == null ? DEFAULT_PAGE_SIZE : size;
        if (pageNumber < 0 || pageSize < 1) {
            throw new ValidationException("Data validation failed");
        }
        pageSize = Math.min(pageSize, MAX_PAGE_SIZE);

        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        Page<Category> result = repository.findAll(pageable);

        List<CategoryDTO> content = new ArrayList<>();
        for (Category entity : result.getContent()) {
            content.add(CategoryMapper.toDTO(entity));
        }

        return new PageDTO(result.getSize(), result.getNumber(), result.getTotalPages(),
                result.getTotalElements(), result.isFirst(), result.isLast(), content);
    }
}
