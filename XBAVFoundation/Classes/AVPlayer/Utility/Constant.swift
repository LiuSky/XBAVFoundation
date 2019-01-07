//
//  Constant.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import Foundation

// PlayerItem Context
public var videoPlayerItemStatusContext: Int = 101
public var videoPlayerItemBufferEmptyContext: Int = 102
public var videoPlayerItemLikelyToKeepUpContext: Int = 103


/// MARK - 常数
public struct Constant {
    
    // PlayerItem KVO
    public static let kXBVideoPlayerItemStatusKey = "status"
    public static let kXBVideoPlayerItemTracksKey = "tracks"
    public static let kXBVideoPlayerItemDurationKey = "duration"
    public static let kXBVideoPlayerItemCommonMetadata = "commonMetadata"
    public static let kXBVideoPlayerItemsMediaSelectionOptions = "availableMediaCharacteristicsWithMediaSelectionOptions"
    public static let kXBVideoPlayerItemBufferEmptyKey = "playbackBufferEmpty"
    public static let kXBVideoPlayerItemLikelyToKeepUpKey = "playbackLikelyToKeepUp"
    
    /// 加载超时时间
    public static let kXBVideoPlayerLoadingTimeOut: Int = 60
    /// 从指定时间开始加载超时时间
    public static let kXBVideoPlayerSeekingTimeOut: Int = 60
    /// 缓冲超时时间
    public static let kXBVideoPlayerBufferingTimeOut: Int = 60
}
