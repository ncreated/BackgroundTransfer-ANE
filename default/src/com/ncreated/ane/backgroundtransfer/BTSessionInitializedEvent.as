package com.ncreated.ane.backgroundtransfer {
import flash.events.Event;

/**
 * Event dispatched by BackgroundTransfer ANE when session is initialized.
 */
public class BTSessionInitializedEvent extends Event {

    public static const INITIALIZED:String = "initialized"

    public function BTSessionInitializedEvent(session_id:String, running_tasks:Array = null) {
        super(INITIALIZED, false, false);
        _sessionID = session_id;
        _runningTasks = running_tasks;
    }

    private var _sessionID:String;

    public function get sessionID():String {
        return _sessionID;
    }

    private var _runningTasks:Array;

    public function get runningTasks():Array {
        return _runningTasks;
    }
}
}
