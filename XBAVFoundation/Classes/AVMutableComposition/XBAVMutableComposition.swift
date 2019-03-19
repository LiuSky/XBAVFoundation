//
//  XBAVMutableComposition.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/3/19.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// MARK - 音频合成
open class XBAVMutableComposition {
    
    /// 完成
    public typealias CompletionHandler = (_ error: Error?) -> Void
    
    
    /// 合成音频文件
    ///
    /// - Parameters:
    ///   - urls: 合成地址
    ///   - exportUrl: 导出地址
    ///   - completed: 完成
    public static func synthetic(_ urls: [URL],
                                 exportUrl: URL,
                                 completed: @escaping CompletionHandler) {
        
        /*
         AVURLAssetPreferPreciseDurationAndTimingKey: 提供更精确的时长和计时信息
         */
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        let composition = AVMutableComposition(urlAssetInitializationOptions: options)
        let track = composition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                preferredTrackID: kCMPersistentTrackID_Invalid)!
        var position: CMTime = CMTime.zero
        urls.forEach {
            
            let audioAsset = AVURLAsset(url: $0)
            let duration = CMTimeRange(start: CMTime.zero, duration: audioAsset.duration)
            do {
               try track.insertTimeRange(duration, of: audioAsset.tracks(withMediaType: .audio).last!, at: position)
               position = CMTimeAdd(position, duration.duration)
            } catch (let error) {
                completed(error)
            }
        }
        
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
        exportSession.outputURL = exportUrl
        exportSession.outputFileType = AVFileType.m4a
        exportSession.exportAsynchronously(completionHandler: {
            switch exportSession.status {
            case .completed:
                completed(nil)
            case .cancelled:
                completed(nil)
            case .failed:
                completed(exportSession.error)
            default:
                break
            }
        })
    }
}
