package fu.se193114.detail.entity;

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

/**
 * KHONG @ManyToOne sang Master — 2 table gia lap khac database.
 * Khoa ngoai chi la Long masterId tron; thong tin Master lay qua Feign.
 */
@Entity
@Table(name = "details")
@Getter
@Setter
@NoArgsConstructor
public class Detail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "detail_id")
    private Long detailId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "description", length = 100)
    private String description;

    @Column(name = "status", nullable = false, length = 10)
    private String status;

    @Temporal(TemporalType.DATE)
    @Column(name = "start_date", nullable = false)
    private Date startDate;

    @Temporal(TemporalType.DATE)
    @Column(name = "end_date")
    private Date endDate;

    @Column(name = "master_id", nullable = false)
    private Long masterId;
}
