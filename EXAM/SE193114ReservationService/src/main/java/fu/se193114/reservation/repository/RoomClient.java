package fu.se193114.reservation.repository;

import fu.se193114.reservation.dto.RoomApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "room-service", url = "http://localhost:8081")
public interface RoomClient {

    @GetMapping("/api/rooms/{id}")
    RoomApiResponse getRoomById(@PathVariable("id") Long id);
}
