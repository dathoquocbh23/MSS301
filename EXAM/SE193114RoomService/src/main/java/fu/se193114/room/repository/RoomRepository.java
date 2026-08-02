package fu.se193114.room.repository;

import fu.se193114.room.entity.Room;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface RoomRepository extends JpaRepository<Room, Long> {

    boolean existsByRoomNumber(String roomNumber);

    boolean existsByRoomNumberAndRoomIdNot(String roomNumber, Long roomId);

    @Query("SELECT r FROM Room r WHERE "
            + "(:roomType IS NULL OR r.roomType = :roomType) AND "
            + "(:status IS NULL OR r.status = :status)")
    Page<Room> search(@Param("roomType") String roomType, @Param("status") String status, Pageable pageable);
}
