package fu.se193114.department.service;

import fu.se193114.department.dto.DepartmentDTO;
import fu.se193114.department.dto.PageDTO;

public interface DepartmentService {

    DepartmentDTO create(DepartmentDTO dto);

    DepartmentDTO update(Long departmentId, DepartmentDTO dto);

    DepartmentDTO getById(Long departmentId);

    void softDelete(Long departmentId);

    PageDTO list(Integer page, Integer size, String name, String status);
}
