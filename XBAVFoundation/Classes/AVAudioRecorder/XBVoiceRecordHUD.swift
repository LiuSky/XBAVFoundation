//
//  XBVoiceRecordHUD.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/25.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit
import SnapKit

/// MARK - 录音HUD
open class XBVoiceRecordHUD: UIImageView {

    /// 峰值频率
    public var peakPower: Float = 0 {
        didSet {
            self.configRecordingHUDImage(withPeakPower: peakPower)
        }
    }
    
    /// 倒计时的时间(默认10)
    public var timeInterval: Int = 10 {
        didSet {
            if self.disableLabel == false {
                self.showCountdownLabel()
                self.countdownLabel.text = "\(timeInterval)"
            }
        }
    }
    
    /// 提醒按钮
    private lazy var remindButton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.clear
        temButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        temButton.layer.masksToBounds = true
        temButton.layer.cornerRadius = 4
        temButton.titleLabel?.textAlignment = .center
        temButton.setTitle("手指上滑,取消发送", for: .normal)
        return temButton
    }()
    
    /// 麦克风图片
    private lazy var microPhoneImageView: UIImageView = {
        let temImageView = UIImageView()
        temImageView.image = UIImage(named: "RecordingBkg")
        temImageView.contentMode = .scaleAspectFit
        return temImageView
    }()
    
    /// 录音峰值图片View
    private lazy var recordingHUDImageView: UIImageView = {
        let temImageView = UIImageView()
        temImageView.image = UIImage(named: "RecordingSignal001")
        temImageView.contentMode = .scaleAspectFit
        return temImageView
    }()
    
    /// 取消录音图片View
    private lazy var cancelRecordImageView: UIImageView = {
        let temImageView = UIImageView()
        temImageView.image = UIImage(named: "RecordCancel")
        temImageView.isHidden = true
        temImageView.contentMode = .scaleAspectFit
        return temImageView
    }()
    
    /// 倒计时标签
    private lazy var countdownLabel: UILabel = {
        let temLabel = UILabel()
        temLabel.backgroundColor = UIColor.clear
        temLabel.font = UIFont.systemFont(ofSize: 80)
        temLabel.textAlignment = .center
        temLabel.textColor = UIColor.white
        temLabel.isHidden = true
        return temLabel
    }()
    
    /// 禁用倒计时标签(默认为false)
    private var disableLabel: Bool = false
    
    init() {
        
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        self.configView()
        self.configLocation()
    }
    
    
    /// 配置View
    private func configView() {
        self.addSubview(remindButton)
        self.addSubview(microPhoneImageView)
        self.addSubview(recordingHUDImageView)
        self.addSubview(cancelRecordImageView)
        self.addSubview(countdownLabel)
    }
    
    /// 配置位置
    private func configLocation() {
        
        self.remindButton.snp.makeConstraints { (make) in
            make.left.equalTo(4)
            make.right.equalTo(-4)
            make.bottom.equalTo(-8)
            make.height.equalTo(25)
        }
        
        self.microPhoneImageView.snp.makeConstraints { (make) in
            make.left.equalTo(25)
            make.top.equalTo(15)
            make.size.equalTo(CGSize(width: 62, height: 100))
        }
        
        self.recordingHUDImageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.microPhoneImageView.snp.right)
            make.top.equalTo(self.microPhoneImageView.snp.top)
            make.size.equalTo(CGSize(width: 38, height: 100))
        }
        
        self.cancelRecordImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(8)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        
        self.countdownLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.top.equalTo(15)
            make.height.equalTo(100)
        }
    }

    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



// MARK: - Public func
extension XBVoiceRecordHUD {
    
    /// 添加到需要显示的View
    public func startRecordingHUD(at view: UIView) {
        view.addSubview(self)
        self.config(true)
    }
    
    /// 提示手指上滑,取消发送
    public func pauseRecord() {
        
        self.disableLabel = false
        if self.disableLabel && self.timeInterval > 0 {
            self.showCountdownLabel()
            return
        } else {
            self.config(true)
            self.remindButton.backgroundColor = UIColor.clear
            self.remindButton.setTitle("手指上滑,取消发送", for: .normal)
        }
    }
    
    /// 提示手指松开,取消发送
    public func resaueRecord() {
        
        self.disableLabel = true
        self.config(false)
        self.remindButton.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.63)
        self.remindButton.setTitle("手指松开,取消发送", for: .normal)
    }
    
    /// 提示录音太短
    public func shortRecordCompled(_ compled: @escaping (Bool) -> Void) {
        
        self.showCountdownLabel()
        self.countdownLabel.text = "!"
        self.remindButton.backgroundColor = UIColor.clear
        self.remindButton.setTitle("说话时间太短", for: .normal)
        self.dismissCompled(compled, duration: 1.5)
    }

    /// 停止录音,意思是完成录音
    public func stopRecordCompled(_ compled: ((Bool) -> Void)? = nil) {
        self.dismissCompled(compled, duration: 0.3)
    }
    
    /// 取消录音
    public func cancelRecordCompled(_ compled: ((Bool) -> Void)? = nil) {
        self.dismissCompled(compled, duration: 0.3)
    }
}

/// MARK - private func
extension XBVoiceRecordHUD {
    
    /// 配置录音
    private func config(_ recoding: Bool) {
        self.microPhoneImageView.isHidden = !recoding
        self.recordingHUDImageView.isHidden = !recoding
        self.cancelRecordImageView.isHidden = recoding
        self.countdownLabel.isHidden = true
    }
    
    /// 显示倒计时标签
    private func showCountdownLabel() {
        
        self.microPhoneImageView.isHidden = true
        self.recordingHUDImageView.isHidden = true
        self.cancelRecordImageView.isHidden = true
        self.countdownLabel.isHidden = false
    }
    
    /// 隐藏
    private func dismissCompled(_ compled: ((Bool) -> Void)? = nil, duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.alpha = 0.0
        }) { finished in
            super.removeFromSuperview()
            self.alpha = 1.0
            self.pauseRecord()
            compled?(finished)
        }
    }
    
    /// 配置录音分贝大小
    private func configRecordingHUDImage(withPeakPower peakPower: Float) {
        
        var imageName = "RecordingSignal00"
        if peakPower >= 0 && peakPower <= 0.1 {
            imageName = imageName.appending("1")
        } else if peakPower > 0.1 && peakPower <= 0.2 {
            imageName = imageName.appending("2")
        } else if peakPower > 0.3 && peakPower <= 0.4 {
            imageName = imageName.appending("3")
        } else if peakPower > 0.4 && peakPower <= 0.5 {
            imageName = imageName.appending("4")
        } else if peakPower > 0.5 && peakPower <= 0.6 {
            imageName = imageName.appending("5")
        } else if peakPower > 0.7 && peakPower <= 0.8 {
            imageName = imageName.appending("6")
        } else if peakPower > 0.8 && peakPower <= 0.9 {
            imageName = imageName.appending("7")
        } else if peakPower > 0.9 && peakPower <= 1.0 {
            imageName = imageName.appending("8")
        } else {
            imageName = imageName.appending("1")
        }
        self.recordingHUDImageView.image = UIImage(named: imageName)
    }
}

