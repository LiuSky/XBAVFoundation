//
//  XBVideoPlayerTrackProtocol.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation

/// MARK - XBVideoPlayerTrackProtocol
public protocol XBVideoPlayerTrackProtocol: NSObjectProtocol {
    
    /// 视频流类型 点播 ，直播
    var videoType: XBVideoPlayerType { get set }
    /// 视频地址
    var streamURL: URL? { get set }
    /// 是否播放结束
    var isPlayedToEnd: Bool { get set }
    /// 是否之前载入过
    var isVideoLoadedBefore: Bool { get set }
    /// 当前播放时间
    var videoTime: Int { get set }
    /// 视频总时长
    var videoDuration: Int { get set }
    /// 是否继续上次观看
    var isContinueLastWatchTime: Bool { get set }
    /// 上次视频播放时间位置
    var lastTimeInSeconds: Int { get set }
}
