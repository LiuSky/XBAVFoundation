//
//  XBAVPlayerC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import AVFoundation

/// MARK - 视频，音频播放器(我们这边主要以视频为例子)
final class XBAVPlayerC: UIViewController {

    /// 播放View
    private lazy var playerView: XBVideoPlayerView = {
        let temPlayerView = XBVideoPlayerView()
        temPlayerView.backgroundColor = UIColor.black
        temPlayerView.frame = CGRect(x: 0, y: self.navigationController?.navigationBar.frame.maxY ?? 0, width: view.frame.width, height: view.frame.width*9/16)
        return temPlayerView
    }()
    
    /// 视频播放控制类
    private lazy var videoPlayer: XBVideoPlayer = {
        let temVideoPlayer = XBVideoPlayer(playerLayerView: self.playerView)
        temVideoPlayer.delegate = self
        return temVideoPlayer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "视频播放器"
        self.view.addSubview(playerView)
        self.loadVideo()
    }
    
    /// 加载视频
    private func loadVideo() {
        
        guard let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/245ti8oovkx1hl5005/245/hls_vod_mvp.m3u8") else {
            return
        }
        
        self.videoPlayer.loadVideo(withStreamURL: url)
    }
}


// MARK: - <#XBVideoPlayerDelegate#>
extension XBAVPlayerC: XBVideoPlayerDelegate {
    
    /// MARK - XBVideoPlayerDelegate
    func videoPlayer(_ videoPlayer: XBVideoPlayer, willPlay track: XBVideoPlayerTrackProtocol) {
        debugPrint(track.videoDuration)
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, shouldPlay track: XBVideoPlayerTrackProtocol) -> Bool {
        return true
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, didUpdatePlayTime playTime: TimeInterval) {
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, didEndToPlay track: XBVideoPlayerTrackProtocol) {
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, shouldChangeTo toState: XBVideoPlayerTrackProtocol) -> Bool {
        return true
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, receivedTimeout timeout: XBVideoPlayerTimeOutStatus) {
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, receivedErrorCode errorCode: XBVideoPlayerErrorStatus, error: Error?) {
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, willChangeTo toState: XBVideoPlayerStatus, from fromState: XBVideoPlayerStatus) {
        
    }
    
    func videoPlayer(_ videoPlayer: XBVideoPlayer, track: XBVideoPlayerTrackProtocol, didChangeTo toState: XBVideoPlayerStatus, from fromState: XBVideoPlayerStatus) {
        
        switch toState {
        case .readyToPlay:
            videoPlayer.play()
            debugPrint(track.videoType)
        default:
            break
        }
    }
}
