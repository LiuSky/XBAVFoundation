//
//  XBAudioRecorderC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/24.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import AVFoundation

/// MARK - 录音控制器
final class XBAudioRecorderC: UIViewController, XBAudioSessionProtocol {

    /// 录音
    private lazy var audioRecorder: XBAudioRecorder = XBAudioRecorder()
    
    /// 音频播放
    private var audioPlayer: XBAudioPlayer?
    
    /// 时间标签
    private lazy var timeLabel: UILabel = {
        let tem = UILabel()
        tem.backgroundColor = UIColor.white
        tem.textColor = UIColor.black
        tem.textAlignment = .center
        tem.text = "00:00:00"
        tem.font = UIFont.systemFont(ofSize: 25)
        tem.frame = CGRect(x: 10, y: 80, width: self.view.frame.width - 10 * 2, height: 40)
        return tem
    }()
    
    /// 进度分贝
    private lazy var progressView: UIProgressView = {
        let tem = UIProgressView()
        tem.trackTintColor = UIColor.green
        tem.progressTintColor = UIColor.red
        tem.frame = CGRect(x: 10, y: self.timeLabel.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 20)
        return tem
    }()
    
    /// 准备播放
    private lazy var prepareButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.red
        tem.setTitle("准备录音", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.progressView.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(prepareToRecord), for: .touchUpInside)
        return tem
    }()
    
    /// 录音按钮
    private lazy var recoderButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.black
        tem.setTitle("开始录音", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.prepareButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(recoder), for: .touchUpInside)
        return tem
    }()
    
    
    /// 停止按钮
    private lazy var stopButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.cyan
        tem.setTitle("结束录音", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.recoderButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(stop), for: .touchUpInside)
        return tem
    }()
    
    /// 暂停按钮
    private lazy var pauseButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.lightGray
        tem.setTitle("暂停", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.stopButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(pause), for: .touchUpInside)
        return tem
    }()
    
    /// 开始播放
    private lazy var playButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.yellow
        tem.setTitle("开始播放", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.pauseButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(play), for: .touchUpInside)
        return tem
    }()
    
    /// 播放刚才的录音地址
    private var playUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "录音"
        self.configView()
        self.updateTimeDisplay()
        self.updateMeter()
    }
    
    /// 配置View
    private func configView() {
        self.view.addSubview(timeLabel)
        self.view.addSubview(progressView)
        self.view.addSubview(prepareButton)
        self.view.addSubview(recoderButton)
        self.view.addSubview(stopButton)
        self.view.addSubview(pauseButton)
        self.view.addSubview(playButton)
    }
}


// MARK: - Action
extension XBAudioRecorderC {
    
    /// 准备
    @objc private func prepareToRecord() {
        
        self.timeLabel.text = "准备录音"
        self.audioRecorder.prepareToRecord { (com) in
            if com {
                self.timeLabel.text = "准备录音完成"
            } else {
                self.timeLabel.text = "准备录音失败"
            }
        }
    }
    
    /// 开始录音
    @objc private func recoder() {
        
        if XBAudioRecorder.checkMicPermission() {
            self.audioRecorder.record()
        } else {
            debugPrint("无权限")
        }
    }
    
    /// 停止录音
    @objc private func stop() {
        
        self.audioRecorder.stop { [weak self] (com, url) in
            guard let self = self else { return }
            self.playUrl = url
        }
    }
    
    /// 暂停录音
    @objc private func pause() {
        self.audioRecorder.pause()
    }
    
    /// 播放
    @objc private func play() {
        
        guard let url = self.playUrl else {
            return
        }
        self.audioPlayer = nil
        self.audioPlayer = XBAudioPlayer(url: url)
        self.audioPlayer?.play()
    }
    
    /// 刷新时间
    private func updateTimeDisplay() {
        
        self.audioRecorder.timerHandler = { [weak self] currentTime in
            guard let self = self else { return }
            self.timeLabel.text = self.formatterCurrentTime()
        }
    }
    
    /// 刷新分贝
    private func updateMeter() {
        
        self.audioRecorder.updateMeters = { [weak self] value in
            guard let self = self else { return }
            self.progressView.setProgress(value, animated: true)
        }
    }
    
    /// 当前录音时间
    private func formatterCurrentTime() -> String {
        
        let time: Int64 = Int64(self.audioRecorder.recorder?.currentTime ?? 0)
        let hours = time/3600
        let minutes = (time/60) % 60
        let seconds = time % 60
        return  String(format: "%02i:%02i:%02i", arguments: [hours, minutes, seconds])
    }
    
}
