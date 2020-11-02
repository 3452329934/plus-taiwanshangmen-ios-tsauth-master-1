//
//  VideoRecorderExpressHelper.swift
//  ThinkSNSPlus
//
//  Created by IMAC on 2019/7/6.
//  Copyright © 2019 ZhiYiCX. All rights reserved.
//

import Foundation

class VideoRecorderExportHelper {
    
    static var exportSession: SCAssetExportSession?
    // 裁剪界面完成后导出视频
    @discardableResult
    class func exportVideo(recordSession: SCRecordSession, completionHandler: ((SCAssetExportSession) -> Void)?) -> SCAssetExportSession {
        let exportSession = SCAssetExportSession(asset: recordSession.assetRepresentingSegments())
        exportSession.videoConfiguration.maxFrameRate = 35
        exportSession.outputUrl = recordSession.outputUrl
        exportSession.outputFileType = AVFileType.mp4.rawValue
        exportSession.contextType = SCContextType.auto
        
        let videoConfig = exportSession.videoConfiguration
        videoConfig.size = CGSize(width: 720, height: 720)
        if let completionHandler = completionHandler {
            exportSession.exportAsynchronously {
                completionHandler(exportSession)
            }
        } else {
            exportSession.exportAsynchronously(completionHandler: nil)
        }
        
        return exportSession
    }
    // 录制界面点暂停后导出视频
    class func exportVideo(recordSession: SCRecordSession?, minDuration: CGFloat, completionHandler: ((SCAssetExportSession) -> Void)?) {
        if let session = recordSession {
            exportSession?.cancelExport()
            exportSession = VideoRecorderExportHelper.exportVideo(recordSession: session) { (exportSession) in
                if let _ = exportSession.error {
                    VideoRecorderExportHelper.exportSession = nil
                }
                completionHandler?(exportSession)
            }
        }
    }
    // app将退出的时候先保存video路径
    class func saveNeedRecoverVideoName() {
        if let videoOutputURL = VideoRecorderExportHelper.exportSession?.outputUrl {
            // 仅保存文件名，因为前面的路径每次重启都会变
            UserDefaults.standard.setValue(videoOutputURL.lastPathComponent, forKey: "video_name_need_recover_last_record_video")
            UserDefaults.standard.synchronize()
        }
    }
    // app启动后将未导入图库的视频导入图库
    class func recoverVideoToPhotosAlbum() {
        if let videoOutputName = UserDefaults.standard.string(forKey: "video_name_need_recover_last_record_video") {
            let videoOutputPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoOutputName)
            let saveToCameraRoll = SCSaveToCameraRollOperation()
            saveToCameraRoll.saveVideoURL(videoOutputPath) { _, _ in
                UserDefaults.standard.setValue(nil, forKey: "video_name_need_recover_last_record_video")
                UserDefaults.standard.synchronize()
            }
        }
    }
    // 裁剪后直接导入图库
    class func saveVideoToPhotosAlbum(videoURL: URL, completion: ((String?, Error?) -> Void)?) {
        let saveToCameraRoll = SCSaveToCameraRollOperation()
        UIApplication.shared.beginIgnoringInteractionEvents()
        saveToCameraRoll.saveVideoURL(videoURL) {
            UIApplication.shared.endIgnoringInteractionEvents()
            completion?($0, $1)
            if $1 == nil {
                VideoRecorderExportHelper.exportSession = nil
            }
        }
    }
    
}
