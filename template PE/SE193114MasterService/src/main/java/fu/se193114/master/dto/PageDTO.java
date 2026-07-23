package fu.se193114.master.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * CANH BAO: moi de dinh nghia PageDTO MOI KHAC (ten field, co/khong totalElements...).
 * Sua field cho khop dung bang DTO trong de!
 */
@Getter
@Setter
@NoArgsConstructor
public class PageDTO {

    private int size;
    private int page;
    private int totalPages;
    private long totalElements;
    private boolean first;
    private boolean last;
    private Object content;
}
