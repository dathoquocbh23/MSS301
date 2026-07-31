package fu.se193114.reservation;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients
public class Se193114ReservationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(Se193114ReservationServiceApplication.class, args);
    }

}
