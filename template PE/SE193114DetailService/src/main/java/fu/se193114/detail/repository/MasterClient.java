package fu.se193114.detail.repository;

import fu.se193114.detail.dto.MasterApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "master-service", url = "http://localhost:8081")
public interface MasterClient {

    @GetMapping("/api/masters/{id}")
    MasterApiResponse getMasterById(@PathVariable("id") Long id);
}
