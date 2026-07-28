package fu.se193114.master.repository;

import fu.se193114.master.entity.Master;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface MasterRepository extends JpaRepository<Master, Long> {

    boolean existsByName(String name);

    boolean existsByNameAndMasterIdNot(String name, Long masterId);

    @Query("SELECT m FROM Master m WHERE "
            + "(:name IS NULL OR LOWER(m.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND "
            + "(:ownerName IS NULL OR LOWER(m.owner) LIKE LOWER(CONCAT('%', :ownerName, '%')))")
    Page<Master> search(@Param("name") String name,
                        @Param("ownerName") String ownerName,
                        Pageable pageable);
}
