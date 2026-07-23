package fu.se193114.restaurant.common;

public class DuplicateNameException extends RuntimeException {

    public DuplicateNameException(String message) {
        super(message);
    }
}
