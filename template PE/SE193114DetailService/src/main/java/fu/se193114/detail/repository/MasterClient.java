package fu.se193114.detail.repository;

import fu.se193114.detail.dto.MasterApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

/**
 * OpenFeign goi thang sang MasterService 8081 (KHONG qua gateway 8080)
 * de xin thong tin master, vi 2 service "khac database" khong JOIN duoc.
 */
@FeignClient(name = "master-service", url = "http://localhost:8081")
public interface MasterClient {

    @GetMapping("/api/masters/{id}")
    MasterApiResponse getMasterById(@PathVariable("id") Long id);
}
