package fu.se193114.department.common;

import fu.se193114.department.dto.DepartmentDTO;
import fu.se193114.department.entity.Department;

public final class DepartmentMapper {

    private DepartmentMapper() {
    }

    public static DepartmentDTO toDTO(Department entity) {
        if (entity == null) {
            return null;
        }
        DepartmentDTO dto = new DepartmentDTO();
        dto.setDepartmentId(entity.getDepartmentId());
        dto.setCode(entity.getCode());
        dto.setName(entity.getName());
        dto.setLocation(entity.getLocation());
        dto.setStatus(entity.getStatus());
        dto.setEffectiveDate(entity.getEffectiveDate());
        dto.setParentId(entity.getParentId());
        return dto;
    }

    public static Department toEntity(DepartmentDTO dto) {
        if (dto == null) {
            return null;
        }
        Department entity = new Department();
        entity.setDepartmentId(dto.getDepartmentId());
        entity.setCode(dto.getCode());
        entity.setName(dto.getName());
        entity.setLocation(dto.getLocation());
        entity.setStatus(dto.getStatus());
        entity.setEffectiveDate(dto.getEffectiveDate());
        entity.setParentId(dto.getParentId());
        return entity;
    }
}
