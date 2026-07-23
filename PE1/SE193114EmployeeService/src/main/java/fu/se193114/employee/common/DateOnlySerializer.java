package fu.se193114.employee.common;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;

import java.io.IOException;
import java.util.Date;

/**
 * Writes a date-only value as dd/MM/yyyy, per the specification sample.
 */
public class DateOnlySerializer extends JsonSerializer<Date> {

    @Override
    public void serialize(Date value, JsonGenerator generator, SerializerProvider provider) throws IOException {
        if (value == null) {
            generator.writeNull();
            return;
        }
        generator.writeString(DateOnlySupport.SPEC_FORMAT.format(DateOnlySupport.toLocalDate(value)));
    }
}
