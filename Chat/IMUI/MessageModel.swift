//===--- MessageModel.swift ---------------------------------------------===//
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

class MessageModel: IMUIMessageModel {
    
    private var messageText = ""
    
    init(text: String, out: Bool) {
        let id = UUID().uuidString
        let user = MessageUser()
        let time = MessageModel.formatChatTime()
        let layout = MessageLayout(out: out, size: MessageModel.calculateTextContentSize(text))
        
        messageText = text
        
        super.init(msgId: id, messageStatus: .success, fromUser: user, isOutGoing: out, time: time, type: "text", cellLayout: layout, duration: nil)
    }
    
    override func text() -> String {
        return messageText
    }
    
}

extension MessageModel {
    
    private static func calculateTextContentSize(_ text: String) -> CGSize {
        let textSize  = text.sizeWithConstrainedWidth(with: IMUIMessageCellLayout.bubbleMaxWidth, font: UIFont.systemFont(ofSize: 18))
        return textSize
    }
    
    private static func formatChatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
}
