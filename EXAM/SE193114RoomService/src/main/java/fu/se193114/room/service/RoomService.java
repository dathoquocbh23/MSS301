package fu.se193114.room.service;

import fu.se193114.room.dto.RoomDTO;
import fu.se193114.room.dto.PageDTO;

public interface RoomService {

    RoomDTO create(RoomDTO dto);

    RoomDTO update(Long roomId, RoomDTO dto);

    RoomDTO getById(Long roomId);

    void deactivate(Long roomId);

    PageDTO list(Integer page, Integer size, String roomType, String status);
}
