//
//  XBAVPlayerC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import AVKit
import SnapKit
import AVFoundation

/// MARK - 视频，音频播放器(我们这边主要以视频为例子)
final class XBAVPlayerC: UIViewController, XBAudioSessionProtocol {

    /// 播放View
    private lazy var playerView: XBVideoPlayerView = {
        let temPlayerView = XBVideoPlayerView()
        temPlayerView.backgroundColor = UIColor.black
        temPlayerView.playerLayer.videoGravity = .resizeAspect
        return temPlayerView
    }()
    
    /// 视频播放控制类
    private lazy var videoPlayer: XBVideoPlayer = {
        let temVideoPlayer = XBVideoPlayer(playerLayerView: self.playerView)
        temVideoPlayer.delegate = self
        return temVideoPlayer
    }()
    
    /// 切换字幕
    private lazy var rightButton = UIBarButtonItem(title: "字幕", style: UIBarButtonItem.Style.done, target: self, action: #selector(eventForSwitch))
    
    
    /// 显示标签
    private lazy var displayLabel: UILabel = {
        let temLabel = UILabel()
        temLabel.textColor = UIColor.red
        temLabel.textAlignment = .center
        temLabel.text = "显示视频第一贞图像"
        return temLabel
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
    
    
    deinit {
        debugPrint("释放控制器")
    }
}


// MARK: - private func
extension XBAVPlayerC {
    
    /// 配置View
    private func configView() {
        self.view.addSubview(playerView)
        self.view.addSubview(displayLabel)
        self.view.addSubview(imageView)
    }
    
    /// 配置位置
    private func configLocation() {
        
        self.playerView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            make.top.equalTo(64)
            make.height.equalTo(view.frame.width*9/16)
        }
        
        self.displayLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.imageView.snp.top).offset(-12)
        }
        
        self.imageView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(200)
        }
    }
    
    /// 加载视频
    private func loadVideo() {
        
        
        //https://devstreaming-cdn.apple.com/videos/wwdc/2016/402h429l9d0hy98c9m6/402/hls_vod_mvp.m3u8
        //http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4
        guard let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2016/402h429l9d0hy98c9m6/402/hls_vod_mvp.m3u8") else {
            return
        }
        
        
        self.videoPlayer.loadVideo(withStreamURL: url)
    }
    
    /// 显示视频第一贞图像
    private func displayImageView() {
        
        self.imageView.image = self.videoPlayer.generateFirstThumbnails()
    }
    
    /// 是否有字幕
    private func hasSubtitles() {
        
        guard let _ = videoPlayer.subtitles else {
            self.navigationItem.rightBarButtonItem = nil
            return
        }
        self.navigationItem.rightBarButtonItem = self.rightButton
    }
    
    
    /// 切换字幕事件
    @objc private func eventForSwitch() {
        
        let subtitles = videoPlayer.subtitles!
        let alertC = UIAlertController(title: "选择字幕", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil)
        for (index, item) in subtitles.enumerated() {
            
            alertC.addAction(UIAlertAction(title: item, style: UIAlertAction.Style.default, handler: { (action) in
                self.videoPlayer.subtitlesSelected(subtitles[index])
            }))
        }
        
        alertC.addAction(cancelAction)
        self.present(alertC, animated: true, completion: nil)
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
            debugPrint("准备播放")
            videoPlayer.play()
            self.displayImageView()
            self.hasSubtitles()
        case .loading:
            debugPrint("加载中...")
        default:
            break
        }
    }
}
