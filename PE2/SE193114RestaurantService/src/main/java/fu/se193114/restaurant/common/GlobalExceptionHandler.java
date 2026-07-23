package fu.se193114.restaurant.common;

import fu.se193114.restaurant.dto.ApiResponseDTO;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

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

    @ExceptionHandler(DuplicateNameException.class)
    public ResponseEntity<ApiResponseDTO> handleDuplicateName(DuplicateNameException ex) {
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

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponseDTO> handleAll(Exception ex) {
        log.error("Internal server error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponseDTO.of(0, "Internal server error", null));
    }
}
