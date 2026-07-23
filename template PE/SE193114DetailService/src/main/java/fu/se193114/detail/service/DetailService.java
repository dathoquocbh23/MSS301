package fu.se193114.detail.service;

import fu.se193114.detail.dto.DetailDTO;
import fu.se193114.detail.dto.PageDTO;

public interface DetailService {

    DetailDTO create(DetailDTO dto);

    DetailDTO update(Long detailId, DetailDTO dto);

    DetailDTO getById(Long detailId);

    void delete(Long detailId);

    PageDTO list(int page, int size, String name, String status);
}
