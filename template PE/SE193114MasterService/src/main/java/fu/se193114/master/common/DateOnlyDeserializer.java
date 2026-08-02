package fu.se193114.master.common;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Date;

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
            parsed = LocalDate.parse(value, ValidDate.SPEC_FORMAT);
        } catch (DateTimeParseException ex) {
            if (!ValidDate.ACCEPT_ISO_FALLBACK) {
                throw new IOException(ValidDate.FORMAT_MESSAGE, ex);
            }
            try {
                parsed = LocalDate.parse(value, DateTimeFormatter.ISO_LOCAL_DATE);
            } catch (DateTimeParseException ex2) {
                throw new IOException(ValidDate.FORMAT_MESSAGE, ex2);
            }
        }

        return Date.from(parsed.atStartOfDay(ZoneId.systemDefault()).toInstant());
    }
}
