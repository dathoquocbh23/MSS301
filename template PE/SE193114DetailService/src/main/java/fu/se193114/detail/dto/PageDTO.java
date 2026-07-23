package fu.se193114.detail.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * CANH BAO: moi de dinh nghia PageDTO MOI KHAC — sua field theo dung bang DTO cua de.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PageDTO {

    private int size;
    private int page;
    private int totalPages;
    private long totalElements;
    private boolean first;
    private boolean last;
    private Object content;
}
