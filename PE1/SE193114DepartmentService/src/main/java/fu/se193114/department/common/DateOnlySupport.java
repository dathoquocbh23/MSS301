package fu.se193114.department.common;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Date;

/**
 * Date-only conversions shared by the JSON serializer, deserializer and validator.
 * Everything resolves in the JVM default zone, which is the zone Hibernate uses when
 * mapping the SQL DATE column, so a day never shifts on the way in or out.
 */
public final class DateOnlySupport {

    public static final DateTimeFormatter SPEC_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private DateOnlySupport() {
    }

    public static LocalDate toLocalDate(Date value) {
        return value.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
    }

    public static Date toDate(LocalDate value) {
        return Date.from(value.atStartOfDay(ZoneId.systemDefault()).toInstant());
    }
}
