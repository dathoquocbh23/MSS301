package fu.se193114.restaurant.service;

import fu.se193114.restaurant.dto.PageDTO;

public interface CategoryService {

    PageDTO list(Integer page, Integer size);
}
