package com.ncreated.ane.backgroundtransfer {
import flash.events.Event;

public class BTDebugEvent extends Event {

    public static const INFO:String = "info";

    public function BTDebugEvent(tag:String, message:String) {
        super(INFO);
        this.tag = tag;
        this.message = message;
    }
    public var tag:String;
    public var message:String;
}
}
