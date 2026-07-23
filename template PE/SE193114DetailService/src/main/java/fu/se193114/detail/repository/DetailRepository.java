package fu.se193114.detail.repository;

import fu.se193114.detail.entity.Detail;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DetailRepository extends JpaRepository<Detail, Long> {

    @Query("SELECT d FROM Detail d WHERE " +
            "(:name IS NULL OR LOWER(d.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND " +
            "(:status IS NULL OR d.status = :status)")
    Page<Detail> search(@Param("name") String name, @Param("status") String status, Pageable pageable);
}
