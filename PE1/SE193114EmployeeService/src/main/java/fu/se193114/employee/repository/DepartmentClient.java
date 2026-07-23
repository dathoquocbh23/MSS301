package fu.se193114.employee.repository;

import fu.se193114.employee.dto.DepartmentApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "department-service", url = "http://localhost:8081")
public interface DepartmentClient {

    @GetMapping("/api/departments/{id}")
    DepartmentApiResponse getDepartmentById(@PathVariable("id") Long id);
}
