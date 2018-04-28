//===--- MessageLayout.swift ---------------------------------------------===//
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

class MessageLayout: IMUIMessageCellLayout {
    
    init(out: Bool, size: CGSize) {
        var insets = UIEdgeInsets.zero
        if out {
            insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 15)
        } else {
            insets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 10)
        }
        
        super.init(isOutGoingMessage: out,
                   isNeedShowTime: true,
                   bubbleContentSize: size,
                   bubbleContentInsets: insets,
                   timeLabelContentSize: CGSize(width: 200, height: 20))
    }
    
    override var bubbleContentType: String {
        return "text"
    }
    
    override var bubbleContentView: IMUIMessageContentViewProtocol {
        return IMUITextMessageContentView()
    }
    
}
