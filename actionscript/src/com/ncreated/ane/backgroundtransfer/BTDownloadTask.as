package com.ncreated.ane.backgroundtransfer {
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.ProgressEvent;

/**
 * Background task running in BackgroundTransferANE.
 */
public class BTDownloadTask extends EventDispatcher {

    public function BTDownloadTask(session_id:String, remote_url:String, local_path:String) {
        _sessionID = session_id;
        _remoteURL = remote_url;
        _localPath = local_path;
    }

    private var _sessionID:String;

    public function get sessionID():String {
        return _sessionID;
    }

    private var _remoteURL:String;

    public function get remoteURL():String {
        return _remoteURL;
    }

    private var _localPath:String;

    public function get localPath():String {
        return _localPath;
    }

    /**
     * This ID is used to identify objects both in Actionscript and Native code.
     */
    internal function get taskID():String {
        return _sessionID + ":" + _remoteURL;
    }

    public function resume():void {
        BackgroundTransfer.instance.resumeDownloadTask(this);
    }

    public function suspend():void {
        BackgroundTransfer.instance.suspendDownloadTask(this);
    }

    public function cancel():void {
        BackgroundTransfer.instance.cancelDownloadTask(this);
    }

    internal function dispatchProgress(bytes_written:Number, total_bytes:Number):void {
        dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, bytes_written, total_bytes));
    }

    internal function dispatchCompleted():void {
        dispatchEvent(new Event(Event.COMPLETE));
    }

    internal function dispatchError(error:String):void {
        dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, error));
    }
}
}
