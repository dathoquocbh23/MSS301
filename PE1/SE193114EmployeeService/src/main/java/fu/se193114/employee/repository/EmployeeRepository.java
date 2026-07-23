package fu.se193114.employee.repository;

import fu.se193114.employee.entity.Employee;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EmployeeRepository extends JpaRepository<Employee, Long> {

    @Query("SELECT e FROM Employee e WHERE " +
            "(:name IS NULL OR LOWER(e.fullName) LIKE LOWER(CONCAT('%', :name, '%'))) AND " +
            "(:status IS NULL OR e.status = :status)")
    Page<Employee> search(@Param("name") String name, @Param("status") String status, Pageable pageable);
}
