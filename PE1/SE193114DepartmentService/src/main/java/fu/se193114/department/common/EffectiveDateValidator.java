package fu.se193114.department.common;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.time.LocalDate;
import java.util.Date;

public class EffectiveDateValidator implements ConstraintValidator<ValidEffectiveDate, Date> {

    private static final LocalDate MIN_DATE = LocalDate.of(2000, 1, 1);
    private static final int MAX_DAYS_AHEAD = 360;

    @Override
    public boolean isValid(Date value, ConstraintValidatorContext context) {
        if (value == null) {
            return true;
        }

        LocalDate effectiveDate = DateOnlySupport.toLocalDate(value);
        LocalDate maxDate = LocalDate.now().plusDays(MAX_DAYS_AHEAD);

        return effectiveDate.isAfter(MIN_DATE) && effectiveDate.isBefore(maxDate);
    }
}
