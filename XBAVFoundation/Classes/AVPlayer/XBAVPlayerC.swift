//
//  XBAVPlayerC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation

/// MARK - 视频，音频播放器(我们这边主要以视频为例子)
final class XBAVPlayerC: UIViewController, XBAudioSessionProtocol {

    /// 播放View
    private lazy var playerView: XBVideoPlayerView = {
        let temPlayerView = XBVideoPlayerView()
        temPlayerView.backgroundColor = UIColor.black
        return temPlayerView
    }()
    
    /// 视频播放控制类
    private lazy var videoPlayer: XBVideoPlayer = {
        let temVideoPlayer = XBVideoPlayer(playerLayerView: self.playerView)
        temVideoPlayer.delegate = self
        return temVideoPlayer
    }()
    
    /// 图片View
    private lazy var imageView: UIImageView = {
        let temImageView = UIImageView()
        return temImageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "视频播放器"
        self.setCategory(.playback)
        self.setActive(true)
        self.configView()
        self.configLocation()
        self.loadVideo()
    }
    
    
    /// 配置View
    private func configView() {
        self.view.addSubview(playerView)
        self.view.addSubview(imageView)
    }
    
    /// 配置位置
    private func configLocation() {
        self.playerView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            make.top.equalTo(64)
            make.height.equalTo(view.frame.width*9/16)
        }
        
        self.imageView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(200)
        }
    }
    
    /// 加载视频
    private func loadVideo() {
        
        
//        https://devstreaming-cdn.apple.com/videos/wwdc/2016/402h429l9d0hy98c9m6/402/hls_vod_mvp.m3u8
        guard let url = URL(string: "http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4") else {
            return
        }
//        let path = Bundle.main.path(forResource: "test_264", ofType: "mp4")
//        let url = URL(fileURLWithPath: path!)
        
        self.videoPlayer.loadVideo(withStreamURL: url)
    }
    
    deinit {
        debugPrint("释放控制器")
    }
}


// MARK: - <#XBVideoPlayerDelegate#>
extension XBAVPlayerC: XBVideoPlayerDelegate {
    
    /// MARK - XBVideoPlayerDelegate
    func videoPlayer(_ videoPlayer: XBVideoPlayer, willPlay track: XBVideoPlayerTrackProtocol) {
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
//            debugPrint(track.videoType)
//            debugPrint(track.videoDuration)
            
            /// 时间
            let time = CMTimeMake(value: 1, timescale: 1)
            let times: [NSValue] = [NSValue(time: time)]
            videoPlayer.generateThumbnails(times, width: self.view.frame.width) { (images) in
                guard let temImages = images else {
                    return
                }
                self.imageView.image = temImages[0]
            }
        default:
            break
        }
    }
}
