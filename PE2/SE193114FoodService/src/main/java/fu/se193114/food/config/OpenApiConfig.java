package fu.se193114.food.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI foodServiceOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SE193114 Food Service")
                        .description("Food management REST API")
                        .version("1.0.0"));
    }
}
