package fu.se193114.reservation.repository;

import fu.se193114.reservation.entity.Reservation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {

    @Query("SELECT r FROM Reservation r WHERE "
            + "(:guestName IS NULL OR LOWER(r.guestName) LIKE LOWER(CONCAT('%', :guestName, '%'))) AND "
            + "(:status IS NULL OR r.status = :status)")
    Page<Reservation> search(@Param("guestName") String guestName, @Param("status") String status, Pageable pageable);
}
