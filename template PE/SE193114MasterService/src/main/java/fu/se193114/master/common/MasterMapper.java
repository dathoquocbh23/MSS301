package fu.se193114.master.common;

import fu.se193114.master.dto.MasterDTO;
import fu.se193114.master.entity.Master;

/**
 * Mapper tay entity <-> DTO. Neu DTO field khac ten cot (vd DTO "owner" / cot "owner_name")
 * thi map o day + @Column(name=...) trong entity, KHONG doi ten field DTO.
 */
public final class MasterMapper {

    private MasterMapper() {
    }

    public static MasterDTO toDTO(Master entity) {
        if (entity == null) {
            return null;
        }
        MasterDTO dto = new MasterDTO();
        dto.setMasterId(entity.getMasterId());
        dto.setCode(entity.getCode());
        dto.setName(entity.getName());
        dto.setDescription(entity.getDescription());
        dto.setStatus(entity.getStatus());
        dto.setEffectiveDate(entity.getEffectiveDate());
        return dto;
    }

    public static Master toEntity(MasterDTO dto) {
        if (dto == null) {
            return null;
        }
        Master entity = new Master();
        entity.setMasterId(dto.getMasterId());
        entity.setCode(dto.getCode());
        entity.setName(dto.getName());
        entity.setDescription(dto.getDescription());
        entity.setStatus(dto.getStatus());
        entity.setEffectiveDate(dto.getEffectiveDate());
        return entity;
    }
}
