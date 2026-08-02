package fu.se193114.master.common;

import jakarta.validation.Constraint;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.ResolverStyle;
import java.util.Date;

@Documented
@Constraint(validatedBy = ValidDate.Validator.class)
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidDate {

    DateTimeFormatter SPEC_FORMAT =
            DateTimeFormatter.ofPattern("dd/MM/uuuu").withResolverStyle(ResolverStyle.STRICT);

    boolean ACCEPT_ISO_FALLBACK = true;

    String FORMAT_MESSAGE = "date must be in dd/MM/yyyy format";

    LocalDate MIN_DATE = null;
    boolean MIN_EXCLUSIVE = true;
    String MIN_MESSAGE = "date must be after the minimum date";

    boolean NO_FUTURE = false;
    String NO_FUTURE_MESSAGE = "date must not be in the future";

    boolean FUTURE_ONLY = false;
    boolean FUTURE_ALLOW_TODAY = true;
    String FUTURE_ONLY_MESSAGE = "date must be in the future";

    int MAX_DAYS_FROM_TODAY = 0;
    String MAX_DAYS_MESSAGE = "date must be before today + 360 days";

    String min() default "";

    String max() default "";

    int maxDaysFromToday() default -1;

    boolean noFuture() default false;

    boolean futureOnly() default false;

    String message() default "date is invalid";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    class Validator implements ConstraintValidator<ValidDate, Date> {

        private ValidDate ann;

        @Override
        public void initialize(ValidDate annotation) {
            this.ann = annotation;
        }

        @Override
        public boolean isValid(Date value, ConstraintValidatorContext ctx) {
            if (value == null) {
                return true;
            }
            LocalDate d = DateOnlySerializer.toLocalDate(value);
            LocalDate today = LocalDate.now();
            boolean customMsg = ann != null && !"date is invalid".equals(ann.message());

            LocalDate min = MIN_DATE;
            boolean minExclusive = MIN_EXCLUSIVE;
            String minMessage = MIN_MESSAGE;
            if (ann != null && !ann.min().isEmpty()) {
                min = LocalDate.parse(ann.min());
                minExclusive = true;
                if (customMsg) {
                    minMessage = ann.message();
                }
            }
            if (min != null) {
                boolean ok = minExclusive ? d.isAfter(min) : !d.isBefore(min);
                if (!ok) {
                    return fail(ctx, minMessage);
                }
            }

            if (ann != null && !ann.max().isEmpty()) {
                LocalDate max = LocalDate.parse(ann.max());
                if (!d.isBefore(max)) {
                    return fail(ctx, customMsg ? ann.message() : "date must be before " + ann.max());
                }
            }

            boolean noFuture = NO_FUTURE || (ann != null && ann.noFuture());
            if (noFuture && d.isAfter(today)) {
                return fail(ctx, customMsg && ann.noFuture() ? ann.message() : NO_FUTURE_MESSAGE);
            }

            boolean futureOnly = FUTURE_ONLY || (ann != null && ann.futureOnly());
            if (futureOnly) {
                boolean ok = FUTURE_ALLOW_TODAY ? !d.isBefore(today) : d.isAfter(today);
                if (!ok) {
                    return fail(ctx, customMsg && ann.futureOnly() ? ann.message() : FUTURE_ONLY_MESSAGE);
                }
            }

            int maxDays = (ann != null && ann.maxDaysFromToday() >= 0) ? ann.maxDaysFromToday() : MAX_DAYS_FROM_TODAY;
            String maxDaysMessage = MAX_DAYS_MESSAGE;
            if (ann != null && ann.maxDaysFromToday() >= 0 && customMsg) {
                maxDaysMessage = ann.message();
            }
            if (maxDays > 0 && !d.isBefore(today.plusDays(maxDays))) {
                return fail(ctx, maxDaysMessage);
            }
            return true;
        }

        private boolean fail(ConstraintValidatorContext ctx, String message) {
            ctx.disableDefaultConstraintViolation();
            ctx.buildConstraintViolationWithTemplate(message).addConstraintViolation();
            return false;
        }
    }
}
