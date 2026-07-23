package fu.se193114.restaurant.common;

import fu.se193114.restaurant.dto.CategoryDTO;
import fu.se193114.restaurant.entity.Category;

public final class CategoryMapper {

    private CategoryMapper() {
    }

    public static CategoryDTO toDTO(Category entity) {
        if (entity == null) {
            return null;
        }
        CategoryDTO dto = new CategoryDTO();
        dto.setCategoryId(entity.getCategoryId());
        dto.setName(entity.getName());
        return dto;
    }

    public static Category toEntity(CategoryDTO dto) {
        if (dto == null) {
            return null;
        }
        Category entity = new Category();
        entity.setCategoryId(dto.getCategoryId());
        entity.setName(dto.getName());
        return entity;
    }
}
