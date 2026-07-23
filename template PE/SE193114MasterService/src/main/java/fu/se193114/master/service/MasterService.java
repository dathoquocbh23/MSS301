package fu.se193114.master.service;

import fu.se193114.master.dto.MasterDTO;
import fu.se193114.master.dto.PageDTO;

public interface MasterService {

    MasterDTO create(MasterDTO dto);

    MasterDTO update(Long masterId, MasterDTO dto);

    MasterDTO getById(Long masterId);

    void softDelete(Long masterId);

    PageDTO list(Integer page, Integer size, String name, String status);
}
