package com.ncreated.ane.backgroundtransfer {
import flash.events.EventDispatcher;
import flash.events.StatusEvent;
import flash.external.ExtensionContext;
import flash.utils.Dictionary;

public class BackgroundTransfer extends EventDispatcher {

    private static var EXTENSION_ID:String = "com.ncreated.ane.backgroundtransfer.BackgroundTransfer";

    private static var _instance:BackgroundTransfer;

    public static function get instance():BackgroundTransfer {
        if (!_instance) {
            _instance = new BackgroundTransfer();
        }
        return _instance;
    }

    public function BackgroundTransfer() {
        if (!_extensionContext) {
            try {
                _extensionContext = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
            }
            catch (e:Error) {
                trace("BackgroundTransfer ANE context creation failed.");
            }
            _extensionContext.addEventListener(StatusEvent.STATUS, onStatusEvent);
            _downloadTasks = new Dictionary();
            _initializedSessions = new Array();
        }
    }

    private var _extensionContext:ExtensionContext;
    private var _downloadTasks:Dictionary;
    private var _initializedSessions:Array;

    public function initializeSession(session_id:String):void {
        if (_extensionContext && !isSessionInitialized(session_id)) {
            _extensionContext.call(BTNativeMethods.initializeSession, session_id);
        }
    }

    public function createDownloadTask(session_id:String, remote_url:String, local_path:String):BTDownloadTask {
        var task:BTDownloadTask = new BTDownloadTask(session_id, remote_url, local_path);

        if (_downloadTasks[task.taskID]) {
            // task with this ID already exists (this download is already running within this session)
            return _downloadTasks[task.taskID];
        }

        if (_extensionContext && isSessionInitialized(session_id)) {
            _extensionContext.call(BTNativeMethods.createDownloadTask, session_id, remote_url, local_path);
            _downloadTasks[task.taskID] = task;
            return task;
        }
        return null;
    }

    public function __crashTheApp():void {
        if (_extensionContext) {
            _extensionContext.call("BGT___crashTheApp");
        }
    }

    public function isSessionInitialized(session_id:String):Boolean {
        return _initializedSessions.indexOf(session_id) >= 0;
    }

    internal function resumeDownloadTask(task:BTDownloadTask):void {
        if (_extensionContext && isSessionInitialized(task.sessionID)) {
            _extensionContext.call(BTNativeMethods.resumeDownloadTask, task.taskID);
        }
    }

    internal function suspendDownloadTask(task:BTDownloadTask):void {
        if (_extensionContext && isSessionInitialized(task.sessionID)) {
            _extensionContext.call(BTNativeMethods.suspendDownloadTask, task.taskID);
        }
    }

    internal function cancelDownloadTask(task:BTDownloadTask):void {
        if (_extensionContext && isSessionInitialized(task.sessionID)) {
            _extensionContext.call(BTNativeMethods.cancelDownloadTask, task.taskID);
        }
    }

    private function onSessionInitialized(session_id:String, running_tasks_ids:Array):void {
        _initializedSessions.push(session_id);
        var runningTasks:Array = new Array();

        for (var i:int = 0; i < running_tasks_ids.length; i++) {
            var taskID:String = unescape(running_tasks_ids[i]);// unescape spaces within id
            var taskProperties:Array = _extensionContext.call(BTNativeMethods.getDownloadTaskPropertiesArray, taskID) as Array;

            if (taskProperties) {
                var task:BTDownloadTask = new BTDownloadTask(taskProperties[0], taskProperties[1], taskProperties[2]);
                if (!_downloadTasks[task.taskID]) {
                    _downloadTasks[task.taskID] = task;
                    runningTasks.push(task);
                }
            }
        }

        dispatchEvent(new BTSessionInitializedEvent(session_id, runningTasks));
    }

    private function onDownloadTaskProgress(task_id:String, bytes_written:Number, total_bytes:Number):void {
        var task:BTDownloadTask = _downloadTasks[task_id];
        if (task) {
            task.dispatchProgress(bytes_written, total_bytes);
        }
    }

    private function onDownloadTaskCompleted(task_id:String):void {
        var task:BTDownloadTask = _downloadTasks[task_id];
        delete _downloadTasks[task_id];
        if (task) {
            task.dispatchCompleted();
        }
    }

    private function onDownloadTaskError(task_id:String, error:String):void {
        var task:BTDownloadTask = _downloadTasks[task_id];
        delete _downloadTasks[task_id];
        if (task) {
            task.dispatchError(error);
        }
    }

    private function onStatusEvent(event:StatusEvent):void {
        var data:Array;
        var taskID:String;

        switch (event.level) {
            case BTInternalMessages.SESSION_INITIALIZED:
            {
                data = event.code.split(" ");
                var sessionID:String = data.shift();
                onSessionInitialized(sessionID, data);
                break;
            }
            case BTInternalMessages.DOWNLOAD_TASK_PROGRESS:
            {
                data = event.code.split(" ");
                var totalBytes:Number = parseFloat(data.pop());
                var bytesWritten:Number = parseFloat(data.pop());
                taskID = unescape(data.join(" "));
                onDownloadTaskProgress(taskID, bytesWritten, totalBytes);
                break;
            }
            case BTInternalMessages.DOWNLOAD_TASK_COMPLETED:
            {
                taskID = unescape(event.code);
                onDownloadTaskCompleted(taskID);
                break;
            }
            case BTInternalMessages.DOWNLOAD_TASK_ERROR:
            {
                data = event.code.split(" ");
                taskID = unescape(data.shift());
                var error:String = data.join(" ");
                onDownloadTaskError(taskID, error);
                break;
            }
        }
    }
}
}