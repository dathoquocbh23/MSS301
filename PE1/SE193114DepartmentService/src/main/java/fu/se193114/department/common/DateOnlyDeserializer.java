package fu.se193114.department.common;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Date;

/**
 * Reads a date-only value as a Date at midnight of the JVM default zone. Accepts the
 * dd/MM/yyyy format from the specification, and ISO yyyy-MM-dd as a fallback.
 */
public class DateOnlyDeserializer extends JsonDeserializer<Date> {

    @Override
    public Date deserialize(JsonParser parser, DeserializationContext context) throws IOException {
        String text = parser.getText();
        if (text == null || text.trim().isEmpty()) {
            return null;
        }
        String value = text.trim();

        LocalDate parsed;
        try {
            parsed = LocalDate.parse(value, DateOnlySupport.SPEC_FORMAT);
        } catch (DateTimeParseException ex) {
            try {
                parsed = LocalDate.parse(value, DateTimeFormatter.ISO_LOCAL_DATE);
            } catch (DateTimeParseException ex2) {
                throw new IOException("effectiveDate must be in dd/MM/yyyy format", ex2);
            }
        }

        return DateOnlySupport.toDate(parsed);
    }
}
