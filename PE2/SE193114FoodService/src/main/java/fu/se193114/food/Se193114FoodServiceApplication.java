package fu.se193114.food;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients
public class Se193114FoodServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(Se193114FoodServiceApplication.class, args);
	}

}
