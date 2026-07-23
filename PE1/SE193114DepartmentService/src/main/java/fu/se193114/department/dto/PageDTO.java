package fu.se193114.department.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

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
