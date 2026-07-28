package fu.se193114.master.common;

import fu.se193114.master.dto.CategoryDTO;
import fu.se193114.master.entity.Category;

public final class CategoryMapper {

    private CategoryMapper() {
    }

    public static CategoryDTO toDTO(Category entity) {
        if (entity == null) {
            return null;
        }
        return new CategoryDTO(entity.getCategoryId(), entity.getName());
    }
}
