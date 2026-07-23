package fu.se193114.department.entity;

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
@Table(name = "departments")
@Getter
@Setter
@NoArgsConstructor
public class Department {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "department_id")
    private Long departmentId;

    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Column(name = "code", nullable = false, length = 10, unique = true)
    private String code;

    @Temporal(TemporalType.DATE)
    @Column(name = "effective_date")
    private Date effectiveDate;

    @Column(name = "status", length = 10)
    private String status;

    @Column(name = "location", length = 100)
    private String location;

    @Column(name = "parent_id")
    private Long parentId;
}
