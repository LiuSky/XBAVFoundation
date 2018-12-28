//
//  XBVideoPlayer.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation


/// MARK - 视频播放控制器类
open class XBVideoPlayer: NSObject {
    
    /// AVPlayer
    private var player: AVPlayer? {
        
        didSet {
            
            self.periodicTimeObserver = nil
            self.removePlayerObservers(player: oldValue)
            
            guard let temPlayer = self.player else { return }
            temPlayer.addObserver(self, forKeyPath: Constant.kXBVideoPlayerStatusKey, options: .new, context: nil)
            self.addPeriodicTimeObserver(player: temPlayer)
        }
    }
    
    /// AVURLAsset
    private weak var urlAsset: AVURLAsset?
    
    /// AVPlayerItem
    private var playerItem: AVPlayerItem? {
        
        didSet {
            
            self.removePlayerItemObservers(playerItem: oldValue)
            guard let temPlayerItem = self.playerItem else { return }
            self.addPlayerItemObservers(playerItem: temPlayerItem)
        }
    }
    
    /// 视频追踪对象
    private var track: XBVideoPlayerTrackProtocol! {
        didSet {
            self.clearVideoPlayer()
        }
    }
    
    /// 周期时间观察者
    private var periodicTimeObserver: Any? {
        
        didSet {
            if let oldTimeObserver = oldValue {
                self.player?.removeTimeObserver(oldTimeObserver)
            }
        }
    }
    
    /// 播放视图
    private weak var playerLayerView: XBPlayerLayer!
    
    /// 图像生成器(没办法生成m3u8格式)
    private var imageGenerator: AVAssetImageGenerator?
    
    /// 视频数据源输出
    private var playerItemVideoOutput: AVPlayerItemVideoOutput?
    
    /// 字幕数据
    private(set) var subtitles: [String]?
    
    /// 初始化加载超时时间
    private var loadingTimeOut: Int = Constant.kXBVideoPlayerLoadingTimeOut
    
    /// seek 超时时间
    private var seekingTimeOut: Int = Constant.kXBVideoPlayerSeekingTimeOut
    
    /// 缓冲超时时间
    private var bufferingTimeOut: Int = Constant.kXBVideoPlayerBufferingTimeOut
    
    /// 是否停止拖拉进度
    private var isEndToSeek: Bool = false
    
    /// 播放状态
    private var state: XBVideoPlayerStatus = .unknown {
        
        didSet {
            
            if self.delegate?.videoPlayer(self, shouldChangeTo: self.track) == false {
                return
            }
            
            self.delegate?.videoPlayer(self, track: self.track, willChangeTo: self.state, from: oldValue)
            
            if oldValue == self.state {
                
                if self.isPlaying && self.state == XBVideoPlayerStatus.playing {
                    self.player?.play()
                }
                return
            }
            
            switch oldValue {
            case .loading:
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(urlAssetTimeOut), object: nil)
            case .seeking:
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(setSeekingTimeOut), object: nil)
            case .buffering:
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(setBufferingTimeOut), object: nil)
            case .stopped:
                if state == .playing {
                    return
                }
            default:
                break
            }
            
            
            switch state {
            case .requestStreamURL:
                if oldValue == .playing && self.isPlaying {
                    self.player?.pause()
                }
            case .loading:
                self.perform(#selector(urlAssetTimeOut), with: nil, afterDelay: TimeInterval(self.loadingTimeOut))
            case .readyToPlay:
                self.track.isVideoLoadedBefore = true
            case .seeking:
                self.perform(#selector(setSeekingTimeOut), with: nil, afterDelay: TimeInterval(self.seekingTimeOut))
            case .buffering:
                self.perform(#selector(setBufferingTimeOut), with: nil, afterDelay: TimeInterval(self.bufferingTimeOut))
            case .playing:
                if self.isPlaying == false {
                    self.player?.play()
                }
            case .paused:
                self.player?.pause()
            case .error:
                self.player?.pause()
                self.saveLastWatchTime(withOldState: oldValue)
                self.notify(XBVideoPlayerErrorStatus.avPlayerFail, error: nil)
            case .stopped:
                self.cancleAllTimeOut()
                self.playerItem?.cancelPendingSeeks()
                self.player?.pause()
                self.saveLastWatchTime(withOldState: oldValue)
                self.clearVideoPlayer()
            default:
                break
            }
            self.delegate?.videoPlayer(self, track: self.track, didChangeTo: state, from: oldValue)
        }
    }
    
    
    /// 回调协议
    public weak var delegate: XBVideoPlayerDelegate?
    
    /// 播放速率
    public var rate: Float {
        set {
            
            /// 待修改方式
            if state == .playing {
                self.player?.rate = rate
            }
        }
        get {
           return self.player?.rate ?? 0
        }
    }
    
    /// 音量
    public var volume: Float {
        set {
            self.player?.volume = min(max(0, volume), 1)
        }
        get {
            return self.player?.volume ?? 0
        }
    }
    
    /// 指示播放器的音频输出是否静音,只影响音频静音的播放器实例，而不是设备
    public var isMuted: Bool {
        set {
            self.player?.isMuted = isMuted
        }
        get {
            return self.player?.isMuted ?? false
        }
    }
    
    /// 是否播放中
    public var isPlaying: Bool {
        
        guard let temPlayer = self.player,
            temPlayer.rate > 0.0 else {
                return false
        }
        return true
    }
    
    /// 当前时间
    public var currentTime: TimeInterval {
        
        if self.track.isVideoLoadedBefore == false {
            return TimeInterval(max(self.track.lastTimeInSeconds, 0))
        } else {
            return TimeInterval(CMTimeGetSeconds(self.player?.currentTime() ?? CMTimeMake(value: 0, timescale: 0)))
        }
    }
    
    /// 视频总时间
    public var duration: TimeInterval {
        
        let duration: Float64 = CMTimeGetSeconds(self.player?.currentItem?.duration ?? CMTimeMake(value: 0, timescale: 0))
        
        if duration.isNaN {
            return 0
        }
        return TimeInterval(duration)
    }
    
    /// 缓冲进度可播放的时间
    public var availableDuration: TimeInterval {
        
        guard let temPlayerItem = self.playerItem else {
            return 0
        }
        return temPlayerItem.totalBuffer()
    }
    
    
    /// 初始化
    public override init() {
        super.init()
        self.addInterruptionAndRouteChangeNotification()
    }
    
    /// MARK - 初始化播放层View
    public init(playerLayerView: XBPlayerLayer) {
        self.playerLayerView = playerLayerView
        super.init()
        self.addInterruptionAndRouteChangeNotification()
    }
    
    
    /// MARK - 释放
    deinit {
        
        self.stop()
        self.removeInterruptionAndRouteChangeNotification()
        self.clearVideoPlayer()
        debugPrint("释放播放器")
    }
}



// MARK: - public func
extension XBVideoPlayer {
    
    /// 加载视频
    ///
    /// - Parameter streamURL: 视频地址
    public func loadVideo(withStreamURL streamURL: URL) {
        
        assert(self.playerLayerView != nil, "这种加载方式,播放层view不能为nil,请调用初始化播放层View")
        self.loadVideo(withStreamURL: streamURL, playerLayerView: self.playerLayerView!)
    }
    
    
    /// 加载视频
    ///
    /// - Parameter track: 视频追踪对象
    public func loadVideo(with track: XBVideoPlayerTrack) {
        
        assert(self.playerLayerView != nil, "这种加载方式,播放层view不能为nil,请调用初始化播放层View")
        self.loadVideo(with: track, playerLayerView: self.playerLayerView!)
    }
    
    
    /// 加载视频,可更换播放层
    ///
    /// - Parameters:
    ///   - streamURL: 播放地址
    ///   - playerLayerView: 播放视频View
    public func loadVideo(withStreamURL streamURL: URL, playerLayerView: XBPlayerLayer) {
        let track = XBVideoPlayerTrack(url: streamURL)
        self.loadVideo(with: track, playerLayerView: playerLayerView)
    }
    
    
    /// 播放
    public func play() {
        
        if self.state == XBVideoPlayerStatus.loading ||
            self.state == XBVideoPlayerStatus.unknown ||
            (self.state == XBVideoPlayerStatus.playing && self.isPlaying) {
            return
        }
        self.playContent()
    }
    
    
    /// 暂停
    public func pause() {
        
        if self.isPlaying == false {
            return
        }
        self.pauseContent()
    }
    
    
    /// 停止播放
    public func stop() {
        
        DispatchQueue.mainThread {
            
            if self.state == XBVideoPlayerStatus.unknown ||
                (self.state == XBVideoPlayerStatus.stopped &&
                    self.player == nil &&
                    self.playerItem == nil) {
                return
            }
            self.state = XBVideoPlayerStatus.stopped
        }
    }
    
    /// 跳转到指定时间播放
    ///
    /// - Parameter time: time
    public func seek(to time: TimeInterval) {
        
        guard self.state != .loading else { return }
        
        self.state = XBVideoPlayerStatus.seeking
        self.seekToTime(inSecond: time) { [weak self] (finished) in
            
            guard let self = self else { return }
            
            if finished {
                self.playContent()
            }
        }
    }
    
    
    
    /// 生成首张缩略图
    ///
    /// - Parameter time: 时间
    /// - Parameter width: 宽度
    public func generateFirstThumbnails() -> UIImage? {
        
        let currentTime: CMTime = CMTimeMake(value: self.playerItem?.duration.value ?? 1, timescale: 1)
        guard let buffer = self.playerItemVideoOutput?.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) else {

            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: buffer)
        let image = UIImage(ciImage: ciImage)
        return image
    }
    
    
    /// 生成缩略图
    ///
    /// - Parameters:
    ///   - times: 时间数组
    ///   - width: 图片宽度
    ///   - completion: 完成
    public func generateThumbnails(_ times: [NSValue], width: CGFloat, completion: @escaping ([UIImage]?) -> Void) {
        
        guard let temAsset = self.playerItem?.asset,
              times.count > 0 else {
                completion(nil)
            return
        }
        
        self.imageGenerator = AVAssetImageGenerator(asset: temAsset)
        self.imageGenerator?.maximumSize = CGSize(width: width, height: 0)
        
        var imageCount = times.count
        var images: [UIImage] = []
        
        let handler: AVAssetImageGeneratorCompletionHandler = { (requestedTime, imageRef, actualTime, result, error) in
        
            if result == .succeeded,
               let temImageRef = imageRef {
               let image = UIImage(cgImage: temImageRef)
                    images.append(image)
               }
        
               imageCount = imageCount - 1
               if imageCount == 0 {
                    DispatchQueue.mainThread {
                        completion(images)
                    }
                }
         }
        
        self.imageGenerator?.generateCGImagesAsynchronously(forTimes: times, completionHandler: handler)
    }
    
    
    
    /// 选择字幕
    ///
    /// - Parameter subtitle: 字幕名称
    public func subtitlesSelected(_ subtitle: String) {
        
        let mc = AVMediaCharacteristic.legible
        guard let temAsset = self.playerItem?.asset,
              let group = temAsset.mediaSelectionGroup(forMediaCharacteristic: mc) else {
                return
        }
        
        var selected = false
        group.options.forEach { (options) in
            if options.displayName == subtitle {
                self.playerItem?.select(options, in: group)
                selected = true
            }
        }
        
        if selected == false {
            self.playerItem?.select(nil, in: group)
        }
    }
}



// MARK: - private func
extension XBVideoPlayer {
    
    /// 播放内容
    private func playContent() {
        
        DispatchQueue.mainThread  {
            self.state = XBVideoPlayerStatus.playing
        }
    }
    
    /// 暂停内容
    private func pauseContent() {
        
        self.pauseContentCompletion()
    }
    
    /// 加载视频
    ///
    /// - Parameters:
    ///   - track: 视频追踪对象
    ///   - playerLayerView: 播放视频View
    private func loadVideo(with track: XBVideoPlayerTrack, playerLayerView: XBPlayerLayer?) {
        
        if self.track != nil && (self.state != XBVideoPlayerStatus.error || state != XBVideoPlayerStatus.unknown) {
            self.stop()
        }
        
        if playerLayerView != nil {
            self.playerLayerView = playerLayerView
        }
        
        self.track = track
        self.track.isPlayedToEnd = false
        self.reloadVideoTrack(track)
    }
    
    
    /// 加载视频根据追踪对象
    ///
    /// - Parameter track: 视频追踪对象
    private func reloadVideoTrack(_ track: XBVideoPlayerTrackProtocol) {
        self.state = XBVideoPlayerStatus.requestStreamURL
        switch self.state {
        case .error, .paused, .loading, .requestStreamURL:
            playVideo(with: track)
        default:
            break
        }
    }
    
    /// 播放视频
    ///
    /// - Parameter track: 视频追踪对象
    private func playVideo(with track: XBVideoPlayerTrackProtocol) {
        
        if self.shouldPlay(track) == false {
            return
        }
        
        self.clearVideoPlayer()
        self.getStreamURL(with: track)
    }
    
    
    /// 获取播放地址
    ///
    /// - Parameter track: 视频追踪对象
    private func getStreamURL(with track: XBVideoPlayerTrackProtocol) {
        
        if let temUrl = track.streamURL {
            self.playVideo(withStreamURL: temUrl, playerLayerView: self.playerLayerView!)
        } else {
            
            let error = NSError(domain: XBVideoPlayerErrorStatus.streamNotFound.description, code: XBVideoPlayerErrorStatus.streamNotFound.rawValue, userInfo: nil)
            self.notify(XBVideoPlayerErrorStatus.streamNotFound, error: error)
            return
        }
    }
    
    
    /// 播放视频
    ///
    /// - Parameters:
    ///   - streamURL: 视频地址
    ///   - layerView: 显示视频View
    private func playVideo(withStreamURL streamURL: URL, playerLayerView layerView: XBPlayerLayer) {
        
        guard self.state != XBVideoPlayerStatus.stopped else { return }
        
        
        self.track.streamURL = streamURL
        self.state = XBVideoPlayerStatus.loading
        self.willPlay(self.track)
        self.asyncLoadURLAsset(withStreamURL: streamURL)
    }
    
    
    /// 异步加载AVURLAsset
    ///
    /// - Parameter streamURL: 视频地址
    private func asyncLoadURLAsset(withStreamURL streamURL: URL) {
        
        if let temUrlAsset = self.urlAsset {
            temUrlAsset.cancelLoading()
        }
        
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        let temUrlAsset = AVURLAsset.init(url: streamURL, options: options)
        self.urlAsset = temUrlAsset
        
        
        let keys = [Constant.kXBVideoPlayerTracksKey,
                    Constant.kXBVideoPlayerPlayableKey,
                    Constant.kXBVideoPlayerDurationKey,
                    Constant.kXBVideoPlayerMediaSelectionOptions]
        
        /// 异步载入完成
        let completionHandler: () -> Void = {
            
            DispatchQueue.mainThread {
                
                guard self.state != .stopped else { return }
                guard temUrlAsset.url.absoluteString == streamURL.absoluteString else {
                    let errorStatus = XBVideoPlayerErrorStatus.assetLoadError
                    let error = NSError(domain: errorStatus.description, code: errorStatus.rawValue, userInfo: nil)
                    self.notify(errorStatus, error: error)
                    return
                }
                
                var error: NSError?
                let status = temUrlAsset.statusOfValue(forKey: Constant.kXBVideoPlayerTracksKey, error: &error)
                switch status {
                case .loaded:
                    
                    let duration = CMTimeGetSeconds(temUrlAsset.duration)
                    if streamURL.isFileURL {
                        self.track.videoType = XBVideoPlayerType.local
                        self.track.videoDuration = Int(duration)
                    } else if duration == 0 || duration.isNaN {
                        self.track.videoType = XBVideoPlayerType.live
                        self.track.videoDuration = 0
                    } else {
                          self.track.videoType = XBVideoPlayerType.vod
                          self.track.videoDuration = Int(duration)
                    }
                    
                     self.playerItemVideoOutput = AVPlayerItemVideoOutput()
                     self.playerItem = AVPlayerItem(asset: temUrlAsset)
                     self.playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = false
                     self.playerItem?.add(self.playerItemVideoOutput!)
                     self.loadMediaOptions()
                    
                     /// 判断上次观看时间是否大于视频总时间
                     if self.track.lastTimeInSeconds > self.track.videoDuration {
                        self.track.lastTimeInSeconds = 0
                     }
                    
                    
                     /// 是否继续上次观看,上次视频播放时间位置,视频类型是否属于本地或者点播
                     if self.track.isContinueLastWatchTime &&
                        self.track.lastTimeInSeconds > 0 &&
                        self.track.videoType != XBVideoPlayerType.live {
                        
                        self.playerItem?.seek(to: CMTimeMakeWithSeconds(Float64(self.track!.lastTimeInSeconds), preferredTimescale: 1))
                     }
                    
                    
                     self.player = AVPlayer(playerItem: self.playerItem!)
                     self.player?.appliesMediaSelectionCriteriaAutomatically = true
                     self.playerLayerView?.config(player: self.player!)
                    
                    if #available(iOS 10.0, *) {
                        self.playerItem?.preferredForwardBufferDuration = 1
                        self.player?.automaticallyWaitsToMinimizeStalling = false
                    }
                case .failed, .unknown:
                    self.notify(XBVideoPlayerErrorStatus.assetLoadError, error: error)
                default:
                    break
                }
            }
        }
        
        temUrlAsset.loadValuesAsynchronously(forKeys: keys, completionHandler: completionHandler)
    }
    
    
    /// 暂停播放
    ///
    /// - Parameter completion: 回调
    private func pauseContentCompletion(_ completion: (() -> Void)? = nil) {
        
        DispatchQueue.mainThread {
            
            switch self.playerItem?.status ?? .unknown {
            case .failed:
                self.state = XBVideoPlayerStatus.error
                return
            case .unknown:
                self.state = XBVideoPlayerStatus.loading
                if let temCompletion = completion {
                    temCompletion()
                }
                return
            default:
                break
            }
            
            switch self.player?.status ?? .unknown {
            case .failed:
                self.state = XBVideoPlayerStatus.error
                return
            case .unknown:
                self.state = XBVideoPlayerStatus.loading
                return
            default:
                break
            }
            
            switch self.state {
            case .loading,
                 .readyToPlay,
                 .playing,
                 .paused,
                 .buffering,
                 .seeking,
                 .error:
                self.state = XBVideoPlayerStatus.paused
                if let temCompletion = completion {
                    temCompletion()
                }
                break
            default:
                break
            }
        }
    }
    

    ///  播放指定时间
    ///
    /// - Parameters:
    ///   - time: 指定时间
    ///   - completion: 完成回调
    private func seekToTime(inSecond time: TimeInterval, completion: @escaping (_ finished: Bool) -> Void) {
        self.isEndToSeek = false
        
        /// 完成播放
        let completionHandler: (Bool) -> Void = { [weak self] finished in
            guard let self = self else {
                return
            }
            completion(finished)
            self.isEndToSeek = false
        }

        self.player?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: 1), completionHandler: completionHandler)
    }
    
    
    
    /// MARK - 视频是否播放
    private func shouldPlay(_ track: XBVideoPlayerTrackProtocol) -> Bool {
        return self.delegate?.videoPlayer(self, shouldPlay: track) ?? true
    }
    
    /// MARK - 即将播放回调
    private func willPlay(_ track: XBVideoPlayerTrackProtocol) {
        self.delegate?.videoPlayer(self, willPlay: track)
    }
    
    /// MARK - 通知
    private func notify(_ errorCode: XBVideoPlayerErrorStatus, error: Error? = nil) {
            
        self.cancleAllTimeOut()
        self.delegate?.videoPlayer(self, track: self.track, receivedErrorCode: errorCode, error: error)
    }
    
    /// MARK - 通知超时
    private func notifyTimeOut(_ status: XBVideoPlayerTimeOutStatus) {
        
        DispatchQueue.mainThread {
            self.player?.pause()
            self.saveLastWatchTime(withOldState: self.state)
            self.delegate?.videoPlayer(self, track: self.track, receivedTimeout: status)
        }
    }
    
    /// MARK - 保存最后观看时间
    private func saveLastWatchTime(withOldState oldState: XBVideoPlayerStatus) {
        
        if oldState != XBVideoPlayerStatus.loading && oldState != XBVideoPlayerStatus.requestStreamURL {
            self.track.lastTimeInSeconds = Int(self.currentTime)
            self.track.isVideoLoadedBefore = false
        }
    }
    
    /// 加载资源中字幕数据(显示系统默认语言)
    private func loadMediaOptions() {
        
        let mc = AVMediaCharacteristic.legible
        guard let temAsset = self.playerItem?.asset,
              let group = temAsset.mediaSelectionGroup(forMediaCharacteristic: mc) else {
            return
        }
        
        /// 如果有字幕则显示系统默认语言
        let localeCurrent = Locale.current
        let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: localeCurrent)
        let option = options.first
        self.playerItem?.select(option, in: group)
        
        self.subtitles = group.options.map { $0.displayName }
    }
    
    
    /// 清除视频播放
    private func clearVideoPlayer() {
        self.playerItem = nil
        self.player = nil
    }
}


// MARK: - add & remove notification & kvo & observable
extension XBVideoPlayer {
    
    
    /// 添加播放周期观察者
    ///
    /// - Parameter player: AVPlayer
    private func addPeriodicTimeObserver(player: AVPlayer) {
        
        let block: (CMTime) -> Void = { [weak self] time in
            guard let self = self else { return }
            self.periodicTimeObserver(time: time)
        }
        
        self.periodicTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main, using: block)
    }
    
    
    /// 周期观察者
    ///
    /// - Parameter time: <#time description#>
    private func periodicTimeObserver(time: CMTime) {
        
        let timeInSeconds: TimeInterval = CMTimeGetSeconds(time)
        if timeInSeconds <= 0 {
            return
        }
        
        if self.isPlaying && self.isEndToSeek {
            
            self.track.videoTime = Int(timeInSeconds)
            self.delegate?.videoPlayer(self, track: self.track, didUpdatePlayTime: timeInSeconds)
        }
    }
    
    
    /// 移除AVPlayer 观察者
    ///
    /// - Parameter player: AVPlayer
    private func removePlayerObservers(player: AVPlayer?) {
        
        guard let temPlayer = player else {
            return
        }
        temPlayer.replaceCurrentItem(with: nil)
        temPlayer.removeObserver(self, forKeyPath: Constant.kXBVideoPlayerStatusKey)
    }
    
    
    /// MARK ------------
    /// 添加PlayerItem观察者
    ///
    /// - Parameter playerItem: AVPlayerItem
    private func addPlayerItemObservers(playerItem: AVPlayerItem) {
        
        
        playerItem.addObserver(self, forKeyPath: Constant.kXBVideoPlayerStatusKey, options: .new, context: nil)
        playerItem.addObserver(self, forKeyPath: Constant.kXBVideoPlayerBufferEmptyKey, options: .new, context: nil)
        playerItem.addObserver(self, forKeyPath: Constant.kXBVideoPlayerLikelyToKeepUpKey, options: .new, context: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidPlayToEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFailedToPlay), name: Notification.Name.AVPlayerItemFailedToPlayToEndTime, object: playerItem)
    }
    
    
    /// 移除PlayerItem观察者
    ///
    /// - Parameter playerItem: AVPlayerItem
    private func removePlayerItemObservers(playerItem: AVPlayerItem?) {
        
        guard let temPlayerItem = playerItem else {
            return
        }
        
        temPlayerItem.removeObserver(self, forKeyPath: Constant.kXBVideoPlayerStatusKey)
        temPlayerItem.removeObserver(self, forKeyPath: Constant.kXBVideoPlayerBufferEmptyKey)
        temPlayerItem.removeObserver(self, forKeyPath: Constant.kXBVideoPlayerLikelyToKeepUpKey)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: temPlayerItem)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemFailedToPlayToEndTime, object: temPlayerItem)
    }
    
    
    /// 键值观察者
    ///
    /// - Parameters:
    ///   - keyPath: keyPath
    ///   - object: keyPath
    ///   - change: change
    ///   - context: context
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let temKeyPath = keyPath,
              let temObject = object else {
                return
        }
        
        if let avplay = temObject as? AVPlayer {
            
            if temKeyPath == Constant.kXBVideoPlayerStatusKey {
                switch avplay.status {
                case .failed:
                    self.notify(XBVideoPlayerErrorStatus.avPlayerFail, error: avplay.error)
                default:
                    break
                }
            }
        } else if let avPlayerItem = temObject as? AVPlayerItem {
            
            if temKeyPath == Constant.kXBVideoPlayerBufferEmptyKey {
                
                // 当缓冲是空的时候
                let isBufferEmpty = self.currentTime > 0 && (self.currentTime < self.duration - 1 || self.track.videoType == XBVideoPlayerType.live)
                
                if avPlayerItem.isPlaybackBufferEmpty && isBufferEmpty && self.state == XBVideoPlayerStatus.playing {
                    self.state = XBVideoPlayerStatus.buffering
                }
            } else if temKeyPath == Constant.kXBVideoPlayerLikelyToKeepUpKey {
                
                if avPlayerItem.isPlaybackLikelyToKeepUp {
                    
                    self.isEndToSeek = true
                    if self.isPlaying == false && self.state == XBVideoPlayerStatus.playing {
                        self.player?.play()
                    }
                    if self.state == XBVideoPlayerStatus.buffering {
                        self.state = XBVideoPlayerStatus.playing
                    }
                }
            } else if temKeyPath == Constant.kXBVideoPlayerStatusKey {
                
                switch avPlayerItem.status {
                case .readyToPlay:
                    self.state = XBVideoPlayerStatus.readyToPlay
                case .failed:
                    self.notify(XBVideoPlayerErrorStatus.avPlayerItemFail, error: avPlayerItem.error)
                default:
                    break
                }
            }
        }
    }
    
    
    /// 播放停止通知
    ///
    /// - Parameter notification: 通知
    @objc private func playerDidPlayToEnd(notification: NSNotification) {
        
        self.track.isPlayedToEnd = true
        self.pauseContentCompletion { [weak self] in
            
            guard let self = self else { return }
            self.delegate?.videoPlayer(self, didEndToPlay: self.track)
        }
    }
    
    
    /// 播放错误通知
    ///
    /// - Parameter notification: 通知
    @objc private func playerDidFailedToPlay(notification: NSNotification) {
        
        guard let dic = notification.userInfo,
            let error = dic[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error else {
                return
        }
        self.notify(XBVideoPlayerErrorStatus.avPlayerItemEndFail, error: error)
    }
    
    
    /// MARK -----------
    /// 取消所有超时时间设置
    private func cancleAllTimeOut() {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.urlAssetTimeOut), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.setSeekingTimeOut), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.setBufferingTimeOut), object: nil)
    }
    
    
    /// URLAsset加载超时
    @objc private func urlAssetTimeOut() {
        
        if self.state == XBVideoPlayerStatus.loading {
            self.notifyTimeOut(XBVideoPlayerTimeOutStatus.timeOutLoad)
        }
    }
    

    /// 拉进度条加载超时
    @objc private func setSeekingTimeOut() {
        
        if self.state == XBVideoPlayerStatus.seeking {
            self.notifyTimeOut(XBVideoPlayerTimeOutStatus.outSeek)
        }
    }
    
    
    /// 缓冲加载超时
    @objc private func setBufferingTimeOut() {
        
        if self.state == XBVideoPlayerStatus.buffering {
            self.notifyTimeOut(XBVideoPlayerTimeOutStatus.outBuffer)
        }
    }
    
    
    /// MARK ---------------
    /// 添加中断通知和线路改变通知
    private func addInterruptionAndRouteChangeNotification() {
        
        self.removeInterruptionAndRouteChangeNotification()
        NotificationCenter.default.addObserver(self, selector: #selector(self.interruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.routeChange(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    /// 移除中断通知和线路改变通知
    private func removeInterruptionAndRouteChangeNotification() {
        
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    
    /// 中断通知(一般指的是电话接入,或者其他App播放音视频等)
    @objc private func interruption(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo,
            let typeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeRawValue) else {
                return
        }
        
        switch type {
        case .began:
            
            if self.state == .playing {
                self.pauseContent()
            }
            
        case .ended:
            
            guard let optionRawValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                AVAudioSession.InterruptionOptions(rawValue: optionRawValue) == .shouldResume else {
                    return
            }
            
            if self.track.isPlayedToEnd == true {
                return
            }
            
            DispatchQueue.after(0.3) {
                self.play()
            }
        }
    }
    
    
    /// 线路改变通知(一般指的是耳机的插入拔出)
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
                //如果是在播放状态下拔出耳机，导致系统级暂停播放，而播放状态未改变
                DispatchQueue.after(0.3) {
                    if self.state == .playing {
                        //只有在播放状态下才恢复播放
                        self.play()
                    }
                }
            }
        }
    }
}
