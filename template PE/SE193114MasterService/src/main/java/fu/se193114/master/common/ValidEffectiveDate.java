package fu.se193114.master.common;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * VI DU custom validator (rule ngay cua PE1). Neu de khong yeu cau rule ngay
 * thi xoa annotation nay + EffectiveDateValidator + cho dung trong DTO.
 */
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = EffectiveDateValidator.class)
public @interface ValidEffectiveDate {

    String message() default "effectiveDate must be after 2000-01-01 and before today plus 360 days";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
