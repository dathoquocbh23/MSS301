package fu.se193114.food.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "Foods")
@Getter
@Setter
@NoArgsConstructor
public class Food {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "food_id")
    private Long foodId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "price", nullable = false)
    private Integer price;

    @Column(name = "ingredient", nullable = false, length = 500)
    private String ingredients;

    @Column(name = "restaurant_id", nullable = false)
    private Long restaurantId;

    @Column(name = "status", nullable = false, length = 20)
    private String status;
}
