//
//  XBVideoPlayerTrack.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// MARK - 视频追踪对象
public class XBVideoPlayerTrack: NSObject, XBVideoPlayerTrackProtocol {
    
    /// 视频流类型 点播 ，直播
    public var videoType: XBVideoPlayerType = .vod
    
    /// 视频地址
    public var streamURL: URL?
    
    /// 是否播放结束
    public var isPlayedToEnd: Bool = false
    
    /// 是否之前载入过
    public var isVideoLoadedBefore: Bool = false
    
    /// 当前播放时间
    public var videoTime: Int = 0
    
    /// 视频总时长
    public var videoDuration: Int = 0
    
    /// 是否继续上次观看
    public var isContinueLastWatchTime: Bool = false
    
    /// 上次视频播放时间位置
    public var lastTimeInSeconds: Int = 0
    
    /// 初始化
    public init(url: URL) {
        self.streamURL = url
    }
    
    /// MARK - 重置
    public func resetTrack() {
        
        self.isContinueLastWatchTime = false
        self.isPlayedToEnd = false
        self.isVideoLoadedBefore = false
        self.lastTimeInSeconds = 0
    }
}
