//===--- XmppManager.swift ------------------------------------------------===//
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

import XMPPFramework
import Toolbox

class XmppManager: NSObject {
    
    static let shared = XmppManager()
    
    /// 消息通知
    static let NotificationMessage = Notification.Name("net.junzz.app.Chat.NotificationMessage")
    
    // Setup xmpp stream
    //
    // The XMPPStream is the base class for all activity.
    // Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    private let xmppStream: XMPPStream = XMPPStream()
    
    // Setup reconnect
    //
    // The XMPPReconnect module monitors for "accidental disconnections" and
    // automatically reconnects the stream for you.
    // There's a bunch more information in the XMPPReconnect header file.
    private let xmppReconnect: XMPPReconnect = XMPPReconnect()
    
    // Setup roster
    //
    // The XMPPRoster handles the xmpp protocol stuff related to the roster.
    // The storage for the roster is abstracted.
    // So you can use any storage mechanism you want.
    // You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
    // or setup your own using raw SQLite, or create your own storage mechanism.
    // You can do it however you like! It's your application.
    // But you do need to provide the roster with some storage facility.
    private var xmppRosterStorage: XMPPRosterCoreDataStorage!
    private var xmppRoster: XMPPRoster!
    
    // Setup vCard support
    //
    // The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
    // The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
    private var xmppvCardTempModule: XMPPvCardTempModule!
    private var xmppvCardAvatarModule: XMPPvCardAvatarModule!
    
    // Setup capabilities
    //
    // The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
    // Basically, when other clients broadcast their presence on the network
    // they include information about what capabilities their client supports (audio, video, file transfer, etc).
    // But as you can imagine, this list starts to get pretty big.
    // This is where the hashing stuff comes into play.
    // Most people running the same version of the same client are going to have the same list of capabilities.
    // So the protocol defines a standardized way to hash the list of capabilities.
    // Clients then broadcast the tiny hash instead of the big list.
    // The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
    // and also persistently storing the hashes so lookups aren't needed in the future.
    //
    // Similarly to the roster, the storage of the module is abstracted.
    // You are strongly encouraged to persist caps information across sessions.
    //
    // The XMPPCapabilitiesCoreDataStorage is an ideal solution.
    // It can also be shared amongst multiple streams to further reduce hash lookups.
    private var xmppCapabilities: XMPPCapabilities!
    
    /// 配置参数。
    private var xmppProfile: XmppProfile!
    
    private var isXmppConnected = false
    
    private override init() {
        super.init()
    }
    
    func setupStream() {
        if xmppRoster != nil {
            "Method setupStream invoked multiple times".log()
        }
        
        // Want xmpp to run in the background?
        xmppStream.enableBackgroundingOnSocket = true
        
        xmppRosterStorage = XMPPRosterCoreDataStorage()
        xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        xmppRoster.autoFetchRoster = true
        xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = true
        
        let xmppvCardStorage = XMPPvCardCoreDataStorage.sharedInstance()
        xmppvCardTempModule = XMPPvCardTempModule(vCardStorage: xmppvCardStorage)
        xmppvCardAvatarModule = XMPPvCardAvatarModule(vCardTempModule: xmppvCardTempModule)
        
        let xmppCapabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
        xmppCapabilities = XMPPCapabilities(capabilitiesStorage: xmppCapabilitiesStorage)
        xmppCapabilities.autoFetchHashedCapabilities = true
        xmppCapabilities.autoFetchNonHashedCapabilities = false
        
        // Activate xmpp modules
        xmppReconnect.activate(xmppStream)
        xmppRoster.activate(xmppStream)
        xmppvCardTempModule.activate(xmppStream)
        xmppvCardAvatarModule.activate(xmppStream)
        xmppCapabilities.activate(xmppStream)
        
        // Add ourself as a delegate to anything we may be interested in
        xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppRoster.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    func teardownStream() {
        xmppStream.removeDelegate(self)
        xmppRoster.removeDelegate(self)
        
        // Deactivate xmpp modules
        xmppReconnect.deactivate()
        xmppRoster.deactivate()
        xmppvCardTempModule.deactivate()
        xmppvCardAvatarModule.deactivate()
        xmppCapabilities.deactivate()
        
        disconnect()
        
        xmppRoster = nil
        xmppRosterStorage = nil
        xmppvCardTempModule = nil
        xmppvCardAvatarModule = nil
        xmppCapabilities = nil
    }
    
    /// 建立连接
    ///
    /// - Parameters:
    ///   - jid: JID
    ///   - hostName: 域名
    ///   - hostPort: 端口
    func connect(_ profile: XmppProfile) -> Bool {
        guard xmppStream.isDisconnected() else {
            return true
        }
        
        xmppProfile = profile
        
        let myJID = xmppProfile.jid
        let myPassword = xmppProfile.password
        let myHostName = xmppProfile.hostName
        
        //
        // If you don't want to use the Settings view to set the JID,
        // uncomment the section below to hard code a JID and password.
        //
        // myJID = @"user@gmail.com/xmppframework";
        // myPassword = @"";
        guard !myJID.isEmpty && !myPassword.isEmpty && !myHostName.isEmpty else {
            return false
        }
        
        // Optional:
        //
        // Replace me with the proper domain and port.
        // The example below is setup for a typical google talk account.
        //
        // If you don't supply a hostName, then it will be automatically resolved using the JID (below).
        // For example, if you supply a JID like 'user@quack.com/rsrc'
        // then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
        //
        // If you don't specify a hostPort, then the default (5222) will be used.
        // xmppStream.hostName = "talk.google.com"
        // xmppStream.hostPort = 5222
        xmppStream.hostName = myHostName
        xmppStream.myJID = XMPPJID(string: myJID)
        
        do {
            try xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
        } catch {
            "Error connecting: \(error.localizedDescription)".log(type: .error)
            return false
        }
        
        return true
    }
    
    /// 断开连接
    func disconnect() {
        goOffline()
        xmppStream.disconnect()
    }
    
    /// 上线
    func goOnline() {
        let presence = XMPPPresence(type: "available")
        xmppStream.send(presence)
    }
    
    /// 下线
    func goOffline() {
        let presence = XMPPPresence(type: "unavailable")
        xmppStream.send(presence)
    }
    
}

extension XmppManager: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ sender: XMPPStream!) {
        "\(#function)".log()
        
        isXmppConnected = true
        
        do {
            try xmppStream.authenticate(withPassword: xmppProfile.password)
        } catch {
            "Error authenticating: \(error.localizedDescription)".log(type: .error)
        }
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error) {
        "\(#function), error: \(error.localizedDescription)".log()
        
        if !isXmppConnected {
            "Unable to connect to server. Check xmppStream.hostName".log(type: .error)
        }
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        "\(#function)".log()
        
        goOnline()
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        "\(#function)".log()
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage) {
        "\(#function)".log()
        
        // A simple example of inbound message handling.
        if message.isChatMessageWithBody() {
            let user = xmppRosterStorage.user(for: message.from(), xmppStream: xmppStream, managedObjectContext: xmppRosterStorage.mainThreadManagedObjectContext)
            
            let body = message.body() ?? "" // message.elements(forName: "body")
            let displayName = user?.displayName ?? ""
            
            let userInfo = [XmppMessage.name.rawValue: displayName, XmppMessage.body.rawValue: body]
            
            NotificationCenter.default.post(name: XmppManager.NotificationMessage, object: self, userInfo: userInfo)
        }
        
        let outMessage = XMPPMessage(type: "chat", to: message.from())
        outMessage?.addBody(message.body())
        
        sender.send(outMessage)
    }
    
}

extension XmppManager: XMPPRosterDelegate {
    
    func xmppRoster(_ sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence) {
        "\(#function)".log()
        
        let user = xmppRosterStorage.user(for: presence.from(), xmppStream: xmppStream, managedObjectContext: xmppRosterStorage.mainThreadManagedObjectContext)
        
        let displayName = user?.displayName ?? ""
        let jidStrBare = presence.fromStr() ?? ""
        let body: String
        
        guard !displayName.isEmpty && !jidStrBare.isEmpty else {
            return
        }
        
        if displayName != jidStrBare {
            body = "Buddy request from \(displayName) <\(jidStrBare)>"
        } else {
            body = "Buddy request from \(displayName)"
        }
        if UIApplication.shared.applicationState == .active {
            // AlertUtils.showAlert(UIViewController, title: displayName, body: body, style: .alert)
            "\(#function): \(body)".log()
        } else {
            // We are not active, so use a local notification instead
            NotificationsUtils.local(title: displayName, body: body, categoryIdentifier: #function, requestIdentifier: #function)
        }
    }
    
}
