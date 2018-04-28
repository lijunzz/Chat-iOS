//===--- XmppProfile.swift ------------------------------------------------===//
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

/// Xmpp 配置参数。
struct XmppProfile {
    
    /// 域名
    let hostName: String
    
    /// 端口号
    let hostPort: UInt16 = 5222
    
    /// JID like 'user@quack.com/rsrc'， 'rsrc' 为 Resource。
    let jid: String
    
    /// 密码
    let password: String
    
}
