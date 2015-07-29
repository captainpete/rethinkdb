package com.rethinkdb;



public class ReqlDriverError extends RethinkDBException {
    public ReqlDriverError(String message) {
        super(message);
    }

    public ReqlDriverError(Throwable cause) {
        super(cause);
    }
}
