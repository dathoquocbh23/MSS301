package fu.se193114.employee.common;

import fu.se193114.employee.dto.DepartmentDTO;
import fu.se193114.employee.dto.EmployeeDTO;
import fu.se193114.employee.entity.Employee;

public class EmployeeMapper {

    private EmployeeMapper() {
    }

    public static EmployeeDTO toDTO(Employee entity) {
        return toDTO(entity, null);
    }

    public static EmployeeDTO toDTO(Employee entity, DepartmentDTO department) {
        if (entity == null) {
            return null;
        }
        EmployeeDTO dto = new EmployeeDTO();
        dto.setEmployeeId(entity.getEmployeeId());
        dto.setFullName(entity.getFullName());
        dto.setEmail(entity.getEmail());
        dto.setPosition(entity.getPosition());
        dto.setStatus(entity.getStatus());
        dto.setStartDate(entity.getStartDate());
        dto.setEndDate(entity.getEndDate());
        dto.setDepartmentId(entity.getDepartmentId());
        dto.setDepartment(department);
        return dto;
    }

    public static Employee toEntity(EmployeeDTO dto) {
        if (dto == null) {
            return null;
        }
        Employee entity = new Employee();
        entity.setFullName(dto.getFullName());
        entity.setEmail(dto.getEmail());
        entity.setPosition(dto.getPosition());
        entity.setStatus(dto.getStatus());
        entity.setStartDate(dto.getStartDate());
        entity.setEndDate(dto.getEndDate());
        entity.setDepartmentId(dto.getDepartmentId());
        return entity;
    }

    /**
     * Applies only the non-null fields present in the DTO onto the existing entity (partial update).
     */
    public static void applyPartialUpdate(Employee entity, EmployeeDTO dto) {
        if (dto.getFullName() != null) {
            entity.setFullName(dto.getFullName());
        }
        if (dto.getEmail() != null) {
            entity.setEmail(dto.getEmail());
        }
        if (dto.getPosition() != null) {
            entity.setPosition(dto.getPosition());
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
        if (dto.getDepartmentId() != null) {
            entity.setDepartmentId(dto.getDepartmentId());
        }
    }
}
