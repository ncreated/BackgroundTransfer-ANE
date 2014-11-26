package com.ncreated.ane.backgroundtransfer {

/**
 * Static consts to address native methods.
 */
internal class BTNativeMethods {

    internal static const initializeSession:String = "BGT_initializeSession";
    internal static const createDownloadTask:String = "BGT_createDownloadTask";
    internal static const getDownloadTaskPropertiesArray:String = "BGT_getDownloadTaskPropertiesArray";
    internal static const resumeDownloadTask:String = "BGT_resumeDownloadTask";
    internal static const suspendDownloadTask:String = "BGT_suspendDownloadTask";
    internal static const cancelDownloadTask:String = "BGT_cancelDownloadTask";
}
}
