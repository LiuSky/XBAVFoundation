//
//  XBAudioRecorderWeChatC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/24.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import SnapKit

/// MARK - 微信录音模仿
final class XBAudioRecorderWeChatC: UIViewController {

    /// 录音帮助类
    private lazy var audioRecorder: XBAudioRecorder = XBAudioRecorder()
    
    /// HUD
    private lazy var voiceRecordHUD: XBVoiceRecordHUD = {
        let temVoiceRecordHUD = XBVoiceRecordHUD()
        return temVoiceRecordHUD
    }()
    
    
    /// 录音按钮
    private lazy var recorderButton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.setTitle("按住 说话", for: .normal)
        temButton.isExclusiveTouch = true
        temButton.adjustsImageWhenHighlighted = false
        temButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        temButton.setTitleColor(UIColor.black, for: .normal)
        temButton.setBackgroundImage(UIImage(named: "VoiceBtn_Black")?.resizable, for: .normal)
        temButton.addTarget(self, action: #selector(startRecordVoice(_:)), for: .touchDown)
        temButton.addTarget(self, action: #selector(cancelRecordVoice(_:)), for: .touchUpOutside)
        temButton.addTarget(self, action: #selector(completeRecordVoice(_:)), for: .touchUpInside)
        temButton.addTarget(self, action: #selector(updateCancelRecordVoice(_:)), for: .touchDragExit)
        temButton.addTarget(self, action: #selector(updateContinueRecordVoice(_:)), for: .touchDragEnter)
        temButton.frame = CGRect(x: 40, y: 400, width: self.view.frame.width - 40 * 2, height: 40)
        return temButton
    }()
    
    //是否取消录音  默认为NO
    private var isCancelled: Bool = false
    //是否正在录音  默认NO
    private var isRecording: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "录音(仿微信)"
        self.view.addSubview(recorderButton)
        self.audioRecorder.maxRecordTime = 20
        self.updateTimeDisplay()
        self.updateMeter()
    }
    
    
    /// 刷新时间
    private func updateTimeDisplay() {
        
        self.audioRecorder.timerHandler = { [weak self] currentTime in
            guard let self = self else { return }
            
            let countdown: Int = Int(self.audioRecorder.maxRecordTime - currentTime)
            if countdown <= 10 {
                self.voiceRecordHUD.timeInterval = countdown
            }
            
            /// 录音到最长了
            if countdown <= 1 {
                self.completeRecordVoice(self.recorderButton)
            }
        }
    }
    
    /// 刷新分贝
    private func updateMeter() {
        
        self.audioRecorder.updateMeters = { [weak self] value in
            guard let self = self else { return }
            self.voiceRecordHUD.peakPower = value
        }
    }
}

// MARK: - Action
extension XBAudioRecorderWeChatC {
    
    /// 开始录音
    @objc private func startRecordVoice(_ sender: UIButton) {
        
        
        if XBAudioRecorder.checkMicPermission() {
            
            self.recorderButton.setTitle("松开 结束", for: .normal)
            self.recorderButton.setBackgroundImage(UIImage(named: "VoiceBtn_BlackHL")?.resizable, for: .normal)
            
            
            self.voiceRecordHUD.startRecordingHUD(at: self.view)
            self.voiceRecordHUD.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.view)
                make.centerY.equalTo(self.view).offset(-44)
                make.size.equalTo(CGSize(width: 150, height: 150))
            }
            
            self.audioRecorder.prepareToRecord { [weak self] (com) in
                guard let self = self else { return }
                if com {
                    self.isRecording = true
                    self.audioRecorder.record()
                }
            }
        } else {
            debugPrint("无权限")
        }
        
    }
    
    /// 取消录音
    @objc private func cancelRecordVoice(_ sender: UIButton) {
        
        //如果已经开始录音了,才需要做取消的动作,否则只要切换 isCancelled 不让录音开始
        if self.isRecording {
            
            sender.setBackgroundImage(UIImage(named: "VoiceBtn_Black")?.resizable, for: .normal)
            sender.setTitle("按住 说话", for: .normal)
            self.voiceRecordHUD.cancelRecordCompled()
            self.audioRecorder.stop { (com, url) in
                debugPrint("删除临时文件")
            }
            
        } else {
            self.isCancelled = true
        }
        
    }
    
    /// 录音完成
    @objc private func completeRecordVoice(_ sender: UIButton) {
        
        if self.isRecording {
            
            sender.setBackgroundImage(UIImage(named: "VoiceBtn_Black")?.resizable, for: .normal)
            sender.setTitle("按住 说话", for: .normal)
            
            self.voiceRecordHUD.cancelRecordCompled()
            self.audioRecorder.stop { (com, url) in
                debugPrint(com, url)
            }
            
        } else {
            self.isCancelled = true
        }
        
    }
    
    /// 更新录音显示状态,手指向上滑动后提示松开取消录音
    @objc private func updateCancelRecordVoice(_ sender: UIButton) {
        
        //如果已经开始录音了,才需要做取消的动作,否则只要切换 isCancelled 不让录音开始
        if self.isRecording {
            self.voiceRecordHUD.resaueRecord()
        } else {
            self.isCancelled = true
        }
    }
    
    /// 更新录音状态,手指重新滑动到范围内,提示向上取消录音
    @objc private func updateContinueRecordVoice(_ sender: UIButton) {
        
        if self.isRecording {
            self.voiceRecordHUD.pauseRecord()
        } else {
            self.isCancelled = true
        }
    }
}


extension UIImage {
    
    /// 九宫格拉伸
    public var resizable: UIImage {
        let widthFloat = floor(self.size.width/2)
        let heightFloat = floor(self.size.height/2)
        return self.resizableImage(withCapInsets: UIEdgeInsets(top: heightFloat, left: widthFloat, bottom: heightFloat, right: widthFloat))
    }
}
