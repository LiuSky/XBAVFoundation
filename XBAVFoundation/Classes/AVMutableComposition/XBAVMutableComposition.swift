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
open class XBAVMutableComposition: NSObject {
    
    /// 合成完成处理
    public typealias CompletionHandler = (_ error: Error?) -> Void
    
    /// 进度处理
    public typealias ProgressHandler = (Float) -> Void
    
    /// 进度
    public var progress: ProgressHandler?
    
    /// 导出会话
    private var exportSession: AVAssetExportSession?
    
    /// 合成进度定时器
    private var progressTimer: Timer?
    
    
    /// 合成音频文件
    ///
    /// - Parameters:
    ///   - urls: 合成地址
    ///   - exportUrl: 导出地址
    ///   - completed: 完成
    public func audioSynthetic(_ urls: [URL],
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
                
               //加入合成轨道之中
               try track.insertTimeRange(duration, of: audioAsset.tracks(withMediaType: .audio).first!, at: position)
               position = CMTimeAdd(position, duration.duration)
            } catch (let error) {
                completed(error)
            }
        }
        
        /// 判断进度block是否存在
        if self.progress != nil {
            self.progressTimer?.invalidate()
            self.progressTimer = Timer(timeInterval: 1,
                                       target: WeakProxy(target: self),
                                       selector: #selector(self.updateProgress),
                                       userInfo: nil,
                                       repeats: true)
            RunLoop.current.add(self.progressTimer!, forMode: .common)
        }
        
        self.exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        self.exportSession!.outputURL = exportUrl
        self.exportSession!.outputFileType = AVFileType.m4a
        
        self.exportSession!.exportAsynchronously(completionHandler: {
            self.progressTimer?.invalidate()
            switch self.exportSession!.status {
            case .completed:
                self.progress?(1.0)
                completed(nil)
            case .cancelled:
                completed(nil)
            case .failed:
                completed(self.exportSession!.error)
            default:
                break
            }
        })
    }
    
    /// 合成视频文件
    ///
    /// - Parameters:
    ///   - urls: 合成地址
    ///   - exportUrl: 导出地址
    ///   - completed: 完成
    public func videoSynthetic(_ urls: [URL],
                               exportUrl: URL,
                               completed: @escaping CompletionHandler) {
        
        let composition = AVMutableComposition(urlAssetInitializationOptions: nil)
        
        let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video,
                                                preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        var position: CMTime = CMTime.zero
        
        urls.forEach {
            
            let videoAsset = AVURLAsset(url: $0, options: nil)
            let duration = CMTimeRange(start: CMTime.zero, duration: videoAsset.duration)
            
            do {
                
                // 视频采集通道
                let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first!
                // 把采集轨道数据加入到可变轨道之中
                try videoTrack.insertTimeRange(duration, of: videoAssetTrack, at: position)
                
                // 音频采集通道
                let audioAssetTrack = videoAsset.tracks(withMediaType: .audio).first!
                // 加入合成轨道之中
                try audioTrack.insertTimeRange(duration, of: audioAssetTrack, at: position)
                
                /// 不知道为何Swift这边处理会导致合成只有一张图
                //position = CMTimeAdd(position, videoAsset.duration)
            } catch (let error) {
                completed(error)
            }
        }
        
        /// 判断进度block是否存在
        if self.progress != nil {
            self.progressTimer?.invalidate()
            self.progressTimer = Timer(timeInterval: 1,
                                       target: WeakProxy(target: self),
                                       selector: #selector(self.updateProgress),
                                       userInfo: nil,
                                       repeats: true)
            RunLoop.current.add(self.progressTimer!, forMode: .common)
        }
        
        self.exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        if let exportSession = self.exportSession {
            exportSession.outputURL = exportUrl
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.outputFileType = AVFileType.mp4
            
            exportSession.exportAsynchronously {
                
                self.progressTimer?.invalidate()
                switch exportSession.status {
                case .completed:
                    self.progress?(1.0)
                    completed(nil)
                case .cancelled:
                    completed(nil)
                case .failed:
                    completed(exportSession.error)
                default:
                    completed(exportSession.error)
                    break
                }
            }
        }
    }

    /// 更新进度
    @objc private func updateProgress() {
        self.progress?(self.exportSession?.progress ?? 0)
    }
    
    /// 取消合成
    public func cancel() {
        self.exportSession?.cancelExport()
    }
    
    
    deinit {
        debugPrint("释放")
    }
}
