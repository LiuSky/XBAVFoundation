//
//  XBVideoPlayerDelegate.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// XBVideoPlayerDelegate
/// 注释:(一个不可避免的限制是，使用@objc修饰的protocol就只能被class实现了，也就是说，对于struct和enum类型，我们是无法令它们所实现的接口中含有可选方法或者属性的,所以这边全部设置为必需实现。比较蛋疼)
public protocol XBVideoPlayerDelegate: NSObjectProtocol {
    
    /// 是否应该播放
    func videoPlayer(_ videoPlayer: XBVideoPlayer, shouldPlay track: XBVideoPlayerTrackProtocol) -> Bool
    
    /// 将要播放
    func videoPlayer(_ videoPlayer: XBVideoPlayer, willPlay track: XBVideoPlayerTrackProtocol)
    
    /// 播放完成
    func videoPlayer(_ videoPlayer: XBVideoPlayer, didEndToPlay track: XBVideoPlayerTrackProtocol)
    
    /// 是否应该改变状态
    func videoPlayer(_ videoPlayer: XBVideoPlayer, shouldChangeTo toState: XBVideoPlayerTrackProtocol) -> Bool
    
    /// 将要改变状态
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, willChangeTo toState: XBVideoPlayerStatus, from fromState: XBVideoPlayerStatus)
    
    /// 已经改变状态
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, didChangeTo toState: XBVideoPlayerStatus, from fromState: XBVideoPlayerStatus)
    
    /// 播放时间定时更新（s）
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, didUpdatePlayTime playTime: TimeInterval)
    
    /// 播放超时
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, receivedTimeout status: XBVideoPlayerTimeOutStatus)
    
    /// 播放出错
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, receivedErrorCode errorCode: XBVideoPlayerErrorStatus, error: Error?)
}
