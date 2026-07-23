package fu.se193114.master.entity;

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
 * DATABASE FIRST: @Table/@Column phai khop TUNG CHU voi script SQL cua de.
 * KHONG dung @OneToMany/@ManyToOne — 2 table gia lap khac database.
 * Cot DATE -> @Temporal(DATE); cot datetime2 -> @Temporal(TIMESTAMP).
 */
@Entity
@Table(name = "masters")
@Getter
@Setter
@NoArgsConstructor
public class Master {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "master_id")
    private Long masterId;

    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Column(name = "code", nullable = false, length = 10, unique = true)
    private String code;

    @Temporal(TemporalType.DATE)
    @Column(name = "effective_date")
    private Date effectiveDate;

    @Column(name = "status", length = 10)
    private String status;

    @Column(name = "description", length = 100)
    private String description;
}
