//
//  XBSpeechSynthesizerC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/22.
//  Copyright © 2018 Sky. All rights reserved.
//

import UIKit


/// MARK - 语音合成器控制器
final class XBSpeechSynthesizerC: UIViewController {
    
    /// 语音合成类
    private lazy var speechSynthesizer = XBSpeechSynthesizer()
    
    /// 文本内容
    private lazy var textView: UITextView = {
        let tem = UITextView()
        tem.backgroundColor = UIColor.red
        tem.font = UIFont.systemFont(ofSize: 18)
        tem.textColor = UIColor.white
        tem.frame = CGRect(x: 10, y: 80, width: self.view.frame.width - 10 * 2, height: 100)
        return tem
    }()
    
    /// 播放状态
    private lazy var stateLabel: UILabel = {
        let temLabel = UILabel()
        temLabel.backgroundColor = UIColor.red
        temLabel.textColor = UIColor.white
        temLabel.textAlignment = .center
        temLabel.frame = CGRect(x: 10, y: textView.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 30)
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
        tem.backgroundColor = UIColor.lightGray
        tem.setTitle("暂停", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.stopButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(pause), for: .touchUpInside)
        return tem
    }()
    
    /// 继续按钮
    private lazy var continueButton: UIButton = {
        let tem = UIButton(type: .custom)
        tem.backgroundColor = UIColor.lightGray
        tem.setTitle("继续", for: .normal)
        tem.setTitleColor(UIColor.white, for: .normal)
        tem.frame = CGRect(x: 10, y: self.pauseButton.frame.maxY + 20, width: self.view.frame.width - 10 * 2, height: 40)
        tem.addTarget(self, action: #selector(continueSpe), for: .touchUpInside)
        return tem
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "语音合成"
        self.configView()
        self.textView.text = "好嗨哦,感觉人生已经达到了巅峰,感觉人生已经达到了高潮,好寂寞,好痛苦"
        self.view.backgroundColor = UIColor.white
    }
    
    /// 配置View
    private func configView() {
        
        self.view.addSubview(self.textView)
        self.view.addSubview(self.stateLabel)
        self.view.addSubview(self.playButton)
        self.view.addSubview(self.pauseButton)
        self.view.addSubview(self.stopButton)
        self.view.addSubview(self.continueButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
}


// MARK: - Action
extension XBSpeechSynthesizerC {
    
    @objc private func play() {
        
        guard self.textView.text.count > 0 else {
            return
        }
        
        self.speechSynthesizer.play(self.textView.text, complete: { (com) in
            self.stateLabel.text = "播放完成"
        })
        
        self.stateLabel.text = "正在播放"
    }
    
    @objc private func stop() {
        self.speechSynthesizer.stop()
        self.stateLabel.text = "停止播放"
    }
    
    @objc private func pause() {
        self.speechSynthesizer.pauseSpeaking()
        self.stateLabel.text = "暂停播放"
    }
    
    @objc private func continueSpe() {
        self.speechSynthesizer.continueSpeaking()
        self.stateLabel.text = "继续播放"
    }
}
