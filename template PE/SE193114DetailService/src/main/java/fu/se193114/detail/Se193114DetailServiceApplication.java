package fu.se193114.detail;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

// QUEN @EnableFeignClients la Feign client khong inject duoc!
@SpringBootApplication
@EnableFeignClients
public class Se193114DetailServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(Se193114DetailServiceApplication.class, args);
    }

}
