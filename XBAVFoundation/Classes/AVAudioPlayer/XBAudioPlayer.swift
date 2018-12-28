//
//  XBAudioPlayer.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/21.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// MARK - 播放协议
public protocol XBAudioPlayerDelegate: NSObjectProtocol {
    
    /// 开始播放
    func playbackBegan()
    
    /// 停止播放
    func playbackStopped()
}


/// MARK - 音频播放类
open class XBAudioPlayer: XBAudioSessionProtocol {
    
    /// 播放事public 件协议
    public weak var delegate: XBAudioPlayerDelegate?
    
    /// 音频播放
    private(set) lazy var audioPlayer: AVAudioPlayer = {
        guard let tem = try? AVAudioPlayer(contentsOf: self.url) else {
            fatalError("请创建正确的url地址")
        }
        tem.prepareToPlay()
        return tem
    }()
    
    /// 播放地址
    private var url: URL
    
    /// 默认只播放一次
    public var numberOfLoops: Int = 0 {
        didSet {
            self.audioPlayer.numberOfLoops = numberOfLoops
        }
    }
    
    init(url: URL) {
        self.url = url
        self.addInterruptionAndRouteChangeNotification()
    }
    
    /// 释放
    deinit {
        self.stop()
        self.removeNotification()
    }
}


// MARK: - public func
extension XBAudioPlayer {
    
    public func play() {
        self.setCategory(.playback)
        self.setActive(true)
        self.audioPlayer.play()
    }
    
    public func stop() {
        self.setActive(false)
        self.audioPlayer.stop()
    }
    
    public func pause() {
        self.audioPlayer.pause()
    }
}



// MARK: - Add Nocation
extension XBAudioPlayer {
    
    /// 添加中断通知和线路改变通知
    private func addInterruptionAndRouteChangeNotification() {
        
        self.removeNotification()
        NotificationCenter.default.addObserver(self, selector: #selector(self.interruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.routeChange(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    /// 移除通知
    private func removeNotification() {
        
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    /// 中断通知事件(一般指的是电话接入,或者其他App播放音视频等)
    @objc private func interruption(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo,
              let typeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeRawValue) else {
               return
        }
        
        switch type {
        case .began:
            self.stop()
            self.delegate?.playbackStopped()
        case .ended:
            
            guard let optionRawValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: optionRawValue) == .shouldResume else {
                return
            }
            self.play()
            self.delegate?.playbackBegan()
        }
    }
    
    
    /// 线路改变事件(一般指的是耳机的插入拔出)
    @objc private func routeChange(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo,
            let typeRawValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let type = AVAudioSession.RouteChangeReason(rawValue: typeRawValue) else {
                return
        }
        
        
        if type == .oldDeviceUnavailable {
            
            guard let routeDescription = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
                let portDescription = routeDescription.outputs.first else {
                    return
            }
            
            /// 原设备为耳机则暂停
            if portDescription.portType == .headphones {
                self.stop()
                self.delegate?.playbackStopped()
            }
        }
        
    }
}
