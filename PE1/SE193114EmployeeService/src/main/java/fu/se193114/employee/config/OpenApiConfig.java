package fu.se193114.employee.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI employeeServiceOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SE193114 Employee Service")
                        .description("Employee management REST API")
                        .version("1.0.0"));
    }
}
