//
//  XBAudioPlayerC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/21.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit

/// MARK - 音频播放控制器
final class XBAudioPlayerC: UIViewController {

    /// 播放类
    private lazy var audioPlayer = XBAudioPlayer(url: Bundle.main.url(forResource: "1", withExtension: "mp3")!)
    
    /// 播放状态
    private lazy var stateLabel: UILabel = {
        let temLabel = UILabel()
        temLabel.backgroundColor = UIColor.red
        temLabel.textColor = UIColor.white
        temLabel.textAlignment = .center
        temLabel.frame = CGRect(x: 10, y: 80, width: self.view.frame.width - 10 * 2, height: 30)
        temLabel.text = "无状态"
        return temLabel
    }()
    
    /// 播放按钮
    private lazy var playButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.black
        tem.setTitle("播放", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.stateLabel.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(play), for: .touchUpInside)
        return tem
    }()
    
    
    /// 停止按钮
    private lazy var stopButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.cyan
        tem.setTitle("停止", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.playButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(stop), for: .touchUpInside)
        return tem
    }()
    
    /// 暂停按钮
    private lazy var pauseButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.cyan
        tem.setTitle("暂停", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.stopButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(pause), for: .touchUpInside)
        return tem
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "音频播放"
        self.configView()
        self.audioPlayer.delegate = self
    }
    
    /// 配置View
    private func configView() {
        self.view.addSubview(self.stateLabel)
        self.view.addSubview(self.playButton)
        self.view.addSubview(self.stopButton)
        self.view.addSubview(self.pauseButton)
    }
    
    deinit {
        debugPrint("释放")
    }
}


// MARK: - Action
extension XBAudioPlayerC {
    
    @objc private func play() {
        self.audioPlayer.play()
        self.stateLabel.text = "正在播放"
    }
    
    @objc private func stop() {
        self.audioPlayer.stop()
        self.stateLabel.text = "停止播放"
    }
    
    @objc private func pause() {
        self.audioPlayer.pause()
        self.stateLabel.text = "暂停播放"
    }
}


// MARK: - <#XBAudioPlayerDelegate#>
extension XBAudioPlayerC: XBAudioPlayerDelegate {
    
    func playbackBegan() {
        self.stateLabel.text = "正在播放"
    }
    
    func playbackStopped() {
        self.stateLabel.text = "暂停播放"
    }
}


