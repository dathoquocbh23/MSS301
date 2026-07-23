package fu.se193114.department.repository;

import fu.se193114.department.entity.Department;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DepartmentRepository extends JpaRepository<Department, Long> {

    boolean existsByCode(String code);

    boolean existsByCodeAndDepartmentIdNot(String code, Long departmentId);

    @Query("SELECT d FROM Department d WHERE "
            + "(:name IS NULL OR LOWER(d.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND "
            + "(:status IS NULL OR d.status = :status)")
    Page<Department> search(@Param("name") String name,
                            @Param("status") String status,
                            Pageable pageable);
}
