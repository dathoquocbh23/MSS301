package fu.se193114.detail.service;

import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.DetailListDTO;

public interface DetailService {

    DetailDTO create(DetailDTO dto);

    DetailDTO update(Long detailId, DetailDTO dto);

    DetailDTO getById(Long detailId);

    void deactivate(Long detailId);

    DetailListDTO list(Integer page, Integer size, String name, String ingredients);
}
