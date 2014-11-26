package com.ncreated.ane.backgroundtransfer {
import flash.events.EventDispatcher;
import flash.utils.Dictionary;

public class BackgroundTransfer extends EventDispatcher {

    private static var EXTENSION_ID:String = "com.ncreated.ane.backgroundtransfer.BackgroundTransfer";

    private static var _instance:BackgroundTransfer;

    public static function get instance():BackgroundTransfer {
        if (!_instance) {
            _instance = new BackgroundTransfer();
            trace("Default implementation of native extension loaded.");
        }
        return _instance;
    }

    public function BackgroundTransfer() {
        _downloadTasks = new Dictionary();
        _initializedSessions = new Array();
    }
    private var _downloadTasks:Dictionary;
    private var _initializedSessions:Array;

    public function initializeSession(session_id:String):void {
        _initializedSessions.push(session_id);
        dispatchEvent(new BTSessionInitializedEvent(session_id, []));
        dispatchEvent(new BTDebugEvent("support", "Native implementation of BackgroundTransfer is not supported on this platform."))
    }

    public function createDownloadTask(session_id:String, remote_url:String, local_path:String):BTDownloadTask {
        return new BTDownloadTask(session_id, remote_url, local_path);
    }

    public function __crashTheApp():void {
        trace("__crashTheApp not supported");
    }

    public function isSessionInitialized(session_id:String):Boolean {
        return _initializedSessions.indexOf(session_id) >= 0;
    }

    internal function resumeDownloadTask(task:BTDownloadTask):void {

    }

    internal function suspendDownloadTask(task:BTDownloadTask):void {

    }

    internal function cancelDownloadTask(task:BTDownloadTask):void {

    }
}
}
