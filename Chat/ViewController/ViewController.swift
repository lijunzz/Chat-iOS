//===--- ViewController.swift ---------------------------------------------===//
//
// Copyright (C) 2018 LiJun
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//===----------------------------------------------------------------------===//

import UIKit

class ViewController: UIViewController {
    
    private let xmppManager = XmppManager.shared
    
    private let imuiMessageCollectionView = IMUIMessageCollectionView()
    private let imuiInputView = IMUIInputView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(receivedMessage(notification:)), name: XmppManager.NotificationMessage, object: xmppManager)
        
        imuiMessageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        imuiMessageCollectionView.delegate = self
        view.addSubview(imuiMessageCollectionView)
        
        imuiInputView.translatesAutoresizingMaskIntoConstraints = false
        imuiInputView.delegate = self
        view.addSubview(imuiInputView)
        
        if #available(iOS 11.0, *) {
            let guide = view.safeAreaLayoutGuide
            
            imuiMessageCollectionView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
            imuiMessageCollectionView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
            imuiMessageCollectionView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
            imuiMessageCollectionView.bottomAnchor.constraint(equalTo: imuiInputView.topAnchor).isActive = true
            
            imuiInputView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            imuiInputView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
            imuiInputView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
            imuiInputView.heightAnchor.constraint(equalToConstant: 81)
        }
        
        /// 连接聊天服务器。
        let xmppProfile = XmppProfile(hostName: "talk.google.com", jid: "user@gmail.com/xmppframework", password: "password")
        _ = xmppManager.connect(xmppProfile)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 收到消息。
    @objc func receivedMessage(notification: Notification) {
        if let userInfo = notification.userInfo {
            let name = userInfo[XmppMessage.name.rawValue] ?? "未知"
            let body = userInfo[XmppMessage.body.rawValue] ?? ""
            
            "\(name) \(body)".log()
        }
    }
    
}

extension ViewController: IMUIMessageMessageCollectionViewDelegate {
    
    func messageCollectionView(_ willBeginDragging: UICollectionView) {
        imuiInputView.hideFeatureView()
    }
    
}

extension ViewController: IMUIInputViewDelegate {
    
    /// IMUIInputView 发送消息。
    func sendTextMessage(_ messageText: String) {
        let message = MessageModel(text: messageText, out: true)
        
        imuiMessageCollectionView.appendMessage(with: message)
    }
    
}


