package fu.se193114.employee.service;

import fu.se193114.employee.dto.EmployeeDTO;
import fu.se193114.employee.dto.PageDTO;

public interface EmployeeService {

    EmployeeDTO create(EmployeeDTO dto);

    EmployeeDTO update(Long employeeId, EmployeeDTO dto);

    EmployeeDTO getById(Long employeeId);

    void delete(Long employeeId);

    PageDTO list(int page, int size, String name, String status);
}
