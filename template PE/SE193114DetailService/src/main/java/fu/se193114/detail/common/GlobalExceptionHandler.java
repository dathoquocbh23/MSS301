package fu.se193114.detail.common;

import fu.se193114.detail.dto.ApiResponseDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final HttpStatus HTTP_VALIDATION = HttpStatus.BAD_REQUEST;
    private static final HttpStatus HTTP_DUPLICATE = HttpStatus.BAD_REQUEST;
    private static final HttpStatus HTTP_NOT_FOUND = HttpStatus.BAD_REQUEST;
    private static final HttpStatus HTTP_BUSINESS = HttpStatus.BAD_REQUEST;
    private static final HttpStatus HTTP_ERROR = HttpStatus.INTERNAL_SERVER_ERROR;

    private static final int ST_VALIDATION = 2;
    private static final int ST_DUPLICATE = 3;
    private static final int ST_NOT_FOUND = 4;
    private static final int ST_BUSINESS = 5;
    private static final int ST_ERROR = 0;

    private static final boolean VALIDATION_MESSAGE_IS_FIXED = true;
    private static final String VALIDATION_MESSAGE = "Data validation failed";
    private static final String ERROR_MESSAGE = "Internal server error";

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ApiResponseDTO> handleNotFound(NotFoundException ex) {
        log.warn(ex.getMessage());
        return ResponseEntity.status(HTTP_NOT_FOUND)
                .body(ApiResponseDTO.of(ST_NOT_FOUND, ex.getMessage(), null));
    }

    @ExceptionHandler(BusinessRuleException.class)
    public ResponseEntity<ApiResponseDTO> handleBusinessRule(BusinessRuleException ex) {
        log.warn(ex.getMessage());
        return ResponseEntity.status(HTTP_BUSINESS)
                .body(ApiResponseDTO.of(ST_BUSINESS, ex.getMessage(), null));
    }

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ApiResponseDTO> handleValidation(ValidationException ex) {
        log.warn("Validation failed: {}", ex.getMessage());
        return ResponseEntity.status(HTTP_VALIDATION)
                .body(ApiResponseDTO.of(ST_VALIDATION, validationMessage(ex.getMessage()), null));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponseDTO> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        List<String> messages = new ArrayList<>();
        for (FieldError fieldError : ex.getBindingResult().getFieldErrors()) {
            messages.add(fieldError.getField() + ": " + fieldError.getDefaultMessage());
        }
        String detail = String.join("; ", messages);
        log.warn("Validation failed: {}", detail);
        return ResponseEntity.status(HTTP_VALIDATION)
                .body(ApiResponseDTO.of(ST_VALIDATION, validationMessage(detail), null));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponseDTO> handleNotReadable(HttpMessageNotReadableException ex) {
        log.warn("Malformed request body: {}", ex.getMessage());
        return ResponseEntity.status(HTTP_VALIDATION)
                .body(ApiResponseDTO.of(ST_VALIDATION, VALIDATION_MESSAGE, null));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponseDTO> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        log.warn("Type mismatch on parameter: {}", ex.getName());
        return ResponseEntity.status(HTTP_VALIDATION)
                .body(ApiResponseDTO.of(ST_VALIDATION, VALIDATION_MESSAGE, null));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponseDTO> handleDataIntegrity(DataIntegrityViolationException ex) {
        log.warn("Database constraint violated: {}", ex.getMostSpecificCause().getMessage());
        return ResponseEntity.status(HTTP_VALIDATION)
                .body(ApiResponseDTO.of(ST_VALIDATION, VALIDATION_MESSAGE, null));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponseDTO> handleAll(Exception ex) {
        log.error(ERROR_MESSAGE, ex);
        return ResponseEntity.status(HTTP_ERROR)
                .body(ApiResponseDTO.of(ST_ERROR, ERROR_MESSAGE, null));
    }

    private String validationMessage(String detail) {
        if (VALIDATION_MESSAGE_IS_FIXED || detail == null || detail.isEmpty()) {
            return VALIDATION_MESSAGE;
        }
        return detail;
    }
}
