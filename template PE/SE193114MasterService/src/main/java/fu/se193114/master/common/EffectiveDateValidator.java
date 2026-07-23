package fu.se193114.master.common;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.Calendar;
import java.util.Date;

public class EffectiveDateValidator implements ConstraintValidator<ValidEffectiveDate, Date> {

    @Override
    public boolean isValid(Date value, ConstraintValidatorContext context) {
        if (value == null) {
            return true;
        }

        // Sua khoang ngay theo yeu cau cua de
        Calendar minCal = Calendar.getInstance();
        minCal.clear();
        minCal.set(2000, Calendar.JANUARY, 1);
        Date minDate = minCal.getTime();

        Calendar maxCal = Calendar.getInstance();
        maxCal.add(Calendar.DAY_OF_MONTH, 360);
        Date maxDate = maxCal.getTime();

        return value.after(minDate) && value.before(maxDate);
    }
}
