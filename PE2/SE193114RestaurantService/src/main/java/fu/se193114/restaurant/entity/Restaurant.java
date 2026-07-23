package fu.se193114.restaurant.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Entity
@Table(name = "restaurants")
@Getter
@Setter
@NoArgsConstructor
public class Restaurant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "restaurant_id")
    private Long restaurantId;

    @Column(name = "name", nullable = false, length = 100, unique = true)
    private String name;

    @Column(name = "owner_name", nullable = false, length = 100)
    private String owner;

    @Column(name = "price_from")
    private Integer priceFrom;

    @Column(name = "price_to")
    private Integer priceTo;

    @Column(name = "phone", nullable = false, length = 11)
    private String phone;

    @Column(name = "address", nullable = false, length = 100)
    private String address;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "open_date", nullable = false)
    private Date openDate;

    @Column(name = "status", nullable = false, length = 10)
    private String status;

    @Column(name = "category_id", nullable = false)
    private Long categoryId;
}
