package fu.se193114.detail.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI detailServiceOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SE193114 Detail Service")
                        .version("1.0.0")
                        .description("REST API for managing details"));
    }
}
