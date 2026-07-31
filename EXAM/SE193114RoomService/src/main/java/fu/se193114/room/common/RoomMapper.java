package fu.se193114.room.common;

import fu.se193114.room.dto.RoomDTO;
import fu.se193114.room.entity.Room;

public final class RoomMapper {

    private RoomMapper() {
    }

    public static RoomDTO toDTO(Room entity) {
        if (entity == null) {
            return null;
        }
        RoomDTO dto = new RoomDTO();
        dto.setRoomId(entity.getRoomId());
        dto.setRoomNumber(entity.getRoomNumber());
        dto.setRoomType(entity.getRoomType());
        dto.setPricePerNight(entity.getPricePerNight());
        dto.setCapacity(entity.getCapacity());
        dto.setFloor(entity.getFloor());
        dto.setStatus(entity.getStatus());
        return dto;
    }

    public static Room toEntity(RoomDTO dto) {
        if (dto == null) {
            return null;
        }
        Room entity = new Room();
        entity.setRoomNumber(dto.getRoomNumber());
        entity.setRoomType(dto.getRoomType());
        entity.setPricePerNight(dto.getPricePerNight());
        entity.setCapacity(dto.getCapacity());
        entity.setFloor(dto.getFloor());
        entity.setStatus(dto.getStatus());
        return entity;
    }

    public static void applyPartialUpdate(Room entity, RoomDTO dto) {
        if (dto.getRoomNumber() != null) {
            entity.setRoomNumber(dto.getRoomNumber());
        }
        if (dto.getRoomType() != null) {
            entity.setRoomType(dto.getRoomType());
        }
        if (dto.getPricePerNight() != null) {
            entity.setPricePerNight(dto.getPricePerNight());
        }
        if (dto.getCapacity() != null) {
            entity.setCapacity(dto.getCapacity());
        }
        if (dto.getFloor() != null) {
            entity.setFloor(dto.getFloor());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
    }
}
