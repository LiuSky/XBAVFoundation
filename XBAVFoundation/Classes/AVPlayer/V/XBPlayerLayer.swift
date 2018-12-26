//
//  XBPlayerLayer.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// MARK - 播放层协议
public protocol XBPlayerLayer: NSObjectProtocol {
    
    /// 获取AVPlayerLayer
    var playerLayer: AVPlayerLayer { get }
    
    /// 配置AVPlayer
    func config(player: AVPlayer)
}
