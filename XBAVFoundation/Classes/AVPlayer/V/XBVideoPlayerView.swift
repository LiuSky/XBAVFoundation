//
//  XBVideoPlayerView.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import AVFoundation

/// MARK - 视频播放View
open class XBVideoPlayerView: UIView, XBPlayerLayer {

    /// 重写layerClass类方法返回一个AVPlayerLayer类
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    /// AVPlayerLayer
    public var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    /// 获取AVPlayer
    public func player() -> AVPlayer {
        return self.playerLayer.player!
    }
    
    /// 配置AVPlayer(将AVPlayer输出的视频指向AVPlayerLayer实例)
    public func config(player: AVPlayer) {
        (self.layer as! AVPlayerLayer).player = player
    }
}
