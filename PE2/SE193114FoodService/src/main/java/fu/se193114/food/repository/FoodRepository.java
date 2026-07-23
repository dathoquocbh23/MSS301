package fu.se193114.food.repository;

import fu.se193114.food.entity.Food;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodRepository extends JpaRepository<Food, Long> {

    @Query("SELECT f FROM Food f WHERE " +
            "(:name IS NULL OR LOWER(f.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND " +
            "(:ingredients IS NULL OR LOWER(f.ingredients) LIKE LOWER(CONCAT('%', :ingredients, '%')))")
    Page<Food> search(@Param("name") String name, @Param("ingredients") String ingredients, Pageable pageable);
}
