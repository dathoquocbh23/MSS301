package fu.se193114.master.common;

import fu.se193114.master.dto.MasterDTO;
import fu.se193114.master.entity.Master;

public final class MasterMapper {

    private MasterMapper() {
    }

    public static MasterDTO toDTO(Master entity) {
        if (entity == null) {
            return null;
        }
        MasterDTO dto = new MasterDTO();
        dto.setMasterId(entity.getMasterId());
        dto.setName(entity.getName());
        dto.setOwner(entity.getOwner());
        dto.setPriceFrom(entity.getPriceFrom());
        dto.setPriceTo(entity.getPriceTo());
        dto.setPhone(entity.getPhone());
        dto.setAddress(entity.getAddress());
        dto.setOpenDate(entity.getOpenDate());
        dto.setStatus(entity.getStatus());
        dto.setCategoryId(entity.getCategoryId());
        return dto;
    }

    public static Master toEntity(MasterDTO dto) {
        if (dto == null) {
            return null;
        }
        Master entity = new Master();
        entity.setName(dto.getName());
        entity.setOwner(dto.getOwner());
        entity.setPriceFrom(dto.getPriceFrom());
        entity.setPriceTo(dto.getPriceTo());
        entity.setPhone(dto.getPhone());
        entity.setAddress(dto.getAddress());
        entity.setOpenDate(dto.getOpenDate());
        entity.setStatus(dto.getStatus());
        entity.setCategoryId(dto.getCategoryId());
        return entity;
    }

    public static void applyPartialUpdate(Master entity, MasterDTO dto) {
        if (dto.getName() != null) {
            entity.setName(dto.getName());
        }
        if (dto.getOwner() != null) {
            entity.setOwner(dto.getOwner());
        }
        if (dto.getPriceFrom() != null) {
            entity.setPriceFrom(dto.getPriceFrom());
        }
        if (dto.getPriceTo() != null) {
            entity.setPriceTo(dto.getPriceTo());
        }
        if (dto.getPhone() != null) {
            entity.setPhone(dto.getPhone());
        }
        if (dto.getAddress() != null) {
            entity.setAddress(dto.getAddress());
        }
        if (dto.getOpenDate() != null) {
            entity.setOpenDate(dto.getOpenDate());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
        if (dto.getCategoryId() != null) {
            entity.setCategoryId(dto.getCategoryId());
        }
    }
}
