package fu.se193114.detail.repository;

import fu.se193114.detail.entity.Detail;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DetailRepository extends JpaRepository<Detail, Long> {

    @Query("SELECT d FROM Detail d WHERE "
            + "(:name IS NULL OR LOWER(d.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND "
            + "(:ingredients IS NULL OR LOWER(d.ingredients) LIKE LOWER(CONCAT('%', :ingredients, '%')))")
    Page<Detail> search(@Param("name") String name,
                        @Param("ingredients") String ingredients,
                        Pageable pageable);
}
