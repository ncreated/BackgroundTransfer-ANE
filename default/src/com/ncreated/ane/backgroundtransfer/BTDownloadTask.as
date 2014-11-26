package com.ncreated.ane.backgroundtransfer {
import com.greensock.events.LoaderEvent;
import com.greensock.loading.DataLoader;
import com.greensock.loading.LoaderMax;
import com.greensock.loading.data.DataLoaderVars;
import com.greensock.loading.data.LoaderMaxVars;

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

public class BTDownloadTask extends EventDispatcher {

    public function BTDownloadTask(session_id:String, remote_url:String, local_path:String) {
        _sessionID = session_id;
        _localPath = local_path;
        _remoteURL = remote_url;

        trace(local_path);
        _targetFile = new File(local_path);
        trace(_targetFile.url);

        const loaderVars:LoaderMaxVars = new LoaderMaxVars();
        loaderVars.onComplete(onComplete);
        loaderVars.onProgress(onProgress);
        loaderVars.onError(onError);
        loaderVars.onIOError(onIOError);

        const dataLoaderVars:DataLoaderVars = new DataLoaderVars();
        dataLoaderVars.format("binary");
        dataLoaderVars.noCache(true);

        const dataLoader:DataLoader = new DataLoader(remote_url, dataLoaderVars);
        dataLoader.name = "dataLoader";

        _loader = new LoaderMax(loaderVars);
        _loader.append(dataLoader);
    }
    private var _targetFile:File;
    private var _loader:LoaderMax;

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

    internal function get taskID():String {
        return _sessionID + ":" + _remoteURL;
    }

    public function resume():void {
        if (_loader.paused) {
            _loader.resume();
        } else {
            _loader.load();
        }
    }

    public function suspend():void {
        _loader.pause();
    }

    public function cancel():void {
        _loader.cancel();
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

    /*
     Loader Max implementation
     */

    private function onProgress(event:LoaderEvent):void {
        dispatchProgress(event.target.bytesLoaded, event.target.bytesTotal);
    }

    private function onComplete(event:LoaderEvent):void {
        var fileStream:FileStream = new FileStream();

        var bytes:ByteArray = _loader.getContent("dataLoader");
        fileStream.open(_targetFile, FileMode.WRITE);
        fileStream.writeBytes(bytes, 0, bytes.bytesAvailable);
        fileStream.close();

        _loader.dispose(true);

        dispatchCompleted();
    }

    private function onError(event:LoaderEvent):void {
        dispatchError(event.text);
    }

    private function onIOError(event:LoaderEvent):void {
        dispatchError(event.text);
    }
}
}
