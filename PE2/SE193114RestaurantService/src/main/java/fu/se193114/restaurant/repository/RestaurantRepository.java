package fu.se193114.restaurant.repository;

import fu.se193114.restaurant.entity.Restaurant;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface RestaurantRepository extends JpaRepository<Restaurant, Long> {

    boolean existsByName(String name);

    boolean existsByNameAndRestaurantIdNot(String name, Long restaurantId);

    @Query("SELECT r FROM Restaurant r WHERE "
            + "(:name IS NULL OR LOWER(r.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND "
            + "(:ownerName IS NULL OR LOWER(r.owner) LIKE LOWER(CONCAT('%', :ownerName, '%')))")
    Page<Restaurant> search(@Param("name") String name,
                            @Param("ownerName") String ownerName,
                            Pageable pageable);
}
