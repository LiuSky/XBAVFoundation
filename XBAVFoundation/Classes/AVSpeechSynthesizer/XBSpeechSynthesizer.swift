//
//  XBSpeechSynthesizer.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/22.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// MARK - 语音合成器
open class XBSpeechSynthesizer: NSObject, XBAudioSessionProtocol {
    
    /// 完成Block
    public typealias Complete = (_ complete: Bool) -> Void
    
    /// MARK - 播放对象
    private lazy var speechSynthesizer: AVSpeechSynthesizer = {
        let tem = AVSpeechSynthesizer()
        tem.delegate = self
        return tem
    }()
    
    /// 默认语言
    private var languageCode = "zh-CN"
    /// 语速
    private var rate = AVSpeechUtteranceDefaultSpeechRate
    /// 音量
    private var volume: Float = 1
    /// 音调
    private var pitchMultiplier: Float = 1
    
    /// 完成回调
    private var complete: Complete?
    
    /// 初始化
    public override init() {}
    
    deinit {
        debugPrint("释放")
    }
}


// MARK: - public func
extension XBSpeechSynthesizer {
    
    /// 播放
    open func play(_ text: String,  complete: Complete? = nil) {
        self.setCategory(.playback)
        self.setActive(true)
        self.complete = complete
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.volume = self.volume
        utterance.pitchMultiplier = self.pitchMultiplier
        utterance.rate = self.rate
        let voiceType = AVSpeechSynthesisVoice(language: self.languageCode)
        utterance.voice = voiceType
        self.speechSynthesizer.speak(utterance)
    }
    
    /// 停止播放
    open func stop() {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    /// 暂停播放
    open func pauseSpeaking() {
        self.speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    /// 继续播放
    open func continueSpeaking() {
        self.speechSynthesizer.continueSpeaking()
    }
    
    /// 设置语言
    public func setLanguage(_ languageCode: String) {
        self.languageCode = languageCode
    }
    
    /// 设置语速
    public func setRate(_ rate: Float) {
        self.rate = rate
    }
    
    /// 设置音量[0-1] Default = 1
    public func setVolume(_ volume: Float) {
        self.volume = volume
    }
    
    /// 设置音调 [0.5 - 2] Default = 1
    public func setPitchMultiplier(_ value: Float) {
        self.pitchMultiplier = value
    }
}


// MARK: - <#AVSpeechSynthesizerDelegate#>
extension XBSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        debugPrint("开始播放")
    }
    
    
    /// 播放完成
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        /// 通知其他app正在播放音乐的接着播放
        self.setActive(false)
        self.complete?(true)
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        debugPrint("暂停播放")
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        debugPrint("继续播放")
    }
    
    /// 取消播放
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        debugPrint("取消")
        self.setActive(false)
        self.complete?(true)
    }
    
    /// 播放进度
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        debugPrint(characterRange)
    }
}
