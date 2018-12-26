//
//  Constant.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import Foundation

/// MARK - 常数
public struct Constant {
    
    // Player KVO
    public static let kXBVideoPlayerTracksKey = "tracks"
    public static let kXBVideoPlayerPlayableKey = "playable"
    public static let kXBVideoPlayerDurationKey = "duration"
    
    // PlayerItem KVO
    public static let kXBVideoPlayerStatusKey = "status"
    public static let kXBVideoPlayerBufferEmptyKey = "playbackBufferEmpty"
    public static let kXBVideoPlayerLikelyToKeepUpKey = "playbackLikelyToKeepUp"

    /// 加载超时时间
    public static let kXBVideoPlayerLoadingTimeOut: Int = 60
    /// 从指定时间开始加载超时时间
    public static let kXBVideoPlayerSeekingTimeOut: Int = 60
    /// 缓冲超时时间
    public static let kXBVideoPlayerBufferingTimeOut: Int = 60
}
