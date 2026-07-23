package fu.se193114.employee.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

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
