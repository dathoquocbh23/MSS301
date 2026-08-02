package fu.se193114.master.service;

import fu.se193114.master.dto.PageDTO;

public interface CategoryService {

    PageDTO list(Integer page, Integer size);
}
