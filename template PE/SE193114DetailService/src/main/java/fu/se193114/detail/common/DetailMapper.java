package fu.se193114.detail.common;

import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.MasterDTO;
import fu.se193114.detail.entity.Detail;

public final class DetailMapper {

    private DetailMapper() {
    }

    public static DetailDTO toDTO(Detail entity) {
        return toDTO(entity, null);
    }

    public static DetailDTO toDTO(Detail entity, MasterDTO master) {
        if (entity == null) {
            return null;
        }
        DetailDTO dto = new DetailDTO();
        dto.setDetailId(entity.getDetailId());
        dto.setName(entity.getName());
        dto.setDescription(entity.getDescription());
        dto.setStatus(entity.getStatus());
        dto.setStartDate(entity.getStartDate());
        dto.setEndDate(entity.getEndDate());
        dto.setMasterId(entity.getMasterId());
        dto.setMaster(master);
        return dto;
    }

    public static Detail toEntity(DetailDTO dto) {
        if (dto == null) {
            return null;
        }
        Detail entity = new Detail();
        entity.setName(dto.getName());
        entity.setDescription(dto.getDescription());
        entity.setStatus(dto.getStatus());
        entity.setStartDate(dto.getStartDate());
        entity.setEndDate(dto.getEndDate());
        entity.setMasterId(dto.getMasterId());
        return entity;
    }

    /**
     * Partial update: chi ghi de field non-null tu DTO len entity co san.
     */
    public static void applyPartialUpdate(Detail entity, DetailDTO dto) {
        if (dto.getName() != null) {
            entity.setName(dto.getName());
        }
        if (dto.getDescription() != null) {
            entity.setDescription(dto.getDescription());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
        if (dto.getStartDate() != null) {
            entity.setStartDate(dto.getStartDate());
        }
        if (dto.getEndDate() != null) {
            entity.setEndDate(dto.getEndDate());
        }
        if (dto.getMasterId() != null) {
            entity.setMasterId(dto.getMasterId());
        }
    }
}
