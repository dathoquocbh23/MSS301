package fu.se193114.detail.common;

import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.DetailResponseDTO;
import fu.se193114.detail.dto.MasterDTO;
import fu.se193114.detail.entity.Detail;

public final class DetailMapper {

    private DetailMapper() {
    }

    public static DetailDTO toDTO(Detail entity) {
        if (entity == null) {
            return null;
        }
        DetailDTO dto = new DetailDTO();
        dto.setDetailId(entity.getDetailId());
        dto.setName(entity.getName());
        dto.setPrice(entity.getPrice());
        dto.setIngredients(entity.getIngredients());
        dto.setMasterId(entity.getMasterId());
        dto.setStatus(entity.getStatus());
        return dto;
    }

    public static DetailDTO toDTO(Detail entity, MasterDTO master) {
        DetailDTO dto = toDTO(entity);
        if (dto != null) {
            dto.setMaster(master);
        }
        return dto;
    }

    public static DetailResponseDTO toResponseDTO(Detail entity, MasterDTO master) {
        if (entity == null) {
            return null;
        }
        DetailResponseDTO dto = new DetailResponseDTO();
        dto.setDetailId(entity.getDetailId());
        dto.setName(entity.getName());
        dto.setPrice(entity.getPrice());
        dto.setIngredients(entity.getIngredients());
        dto.setMaster(master);
        return dto;
    }

    public static Detail toEntity(DetailDTO dto) {
        if (dto == null) {
            return null;
        }
        Detail entity = new Detail();
        entity.setName(dto.getName());
        entity.setPrice(dto.getPrice());
        entity.setIngredients(dto.getIngredients());
        entity.setMasterId(dto.getMasterId());
        entity.setStatus(dto.getStatus());
        return entity;
    }

    public static void applyPartialUpdate(Detail entity, DetailDTO dto) {
        if (dto.getName() != null) {
            entity.setName(dto.getName());
        }
        if (dto.getPrice() != null) {
            entity.setPrice(dto.getPrice());
        }
        if (dto.getIngredients() != null) {
            entity.setIngredients(dto.getIngredients());
        }
        if (dto.getMasterId() != null) {
            entity.setMasterId(dto.getMasterId());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }
    }
}
