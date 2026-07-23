package fu.se193114.department.common;

import fu.se193114.department.dto.ApiResponseDTO;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ApiResponseDTO> handleNotFound(NotFoundException ex) {
        log.warn(ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(4, ex.getMessage(), null));
    }

    @ExceptionHandler(DuplicateCodeException.class)
    public ResponseEntity<ApiResponseDTO> handleDuplicateCode(DuplicateCodeException ex) {
        log.warn(ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(3, ex.getMessage(), null));
    }

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ApiResponseDTO> handleValidation(ValidationException ex) {
        log.warn(ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(2, ex.getMessage(), null));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponseDTO> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        List<String> messages = new ArrayList<>();
        for (FieldError fieldError : ex.getBindingResult().getFieldErrors()) {
            messages.add(fieldError.getDefaultMessage());
        }
        String message = messages.isEmpty() ? "Validation failed" : String.join("; ", messages);
        log.warn(message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(2, message, null));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponseDTO> handleConstraintViolation(ConstraintViolationException ex) {
        List<String> messages = new ArrayList<>();
        for (ConstraintViolation<?> violation : ex.getConstraintViolations()) {
            messages.add(violation.getMessage());
        }
        String message = messages.isEmpty() ? "Validation failed" : String.join("; ", messages);
        log.warn(message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(2, message, null));
    }

    /**
     * An unparsable body (malformed JSON, a date that does not match dd/MM/yyyy, a text
     * value where a number is expected) is a validation failure, not a server fault.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponseDTO> handleUnreadableBody(HttpMessageNotReadableException ex) {
        log.warn("Request body could not be read: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(2, "Request body is invalid", null));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponseDTO> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        log.warn("Parameter type mismatch: {}", ex.getName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(2, ex.getName() + " has an invalid value", null));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResponseDTO> handleMissingParameter(MissingServletRequestParameterException ex) {
        log.warn("Missing request parameter: {}", ex.getParameterName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponseDTO.of(2, ex.getParameterName() + " is required", null));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponseDTO> handleAll(Exception ex) {
        log.error("Internal server error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponseDTO.of(0, "Internal server error", null));
    }
}
