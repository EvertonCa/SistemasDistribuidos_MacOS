//
//  MultipeerSession.swift
//  SistemasDistribuidos
//
//  Created by Everton Cardoso on 14/05/20.
//  Copyright © 2020 Everton Cardoso. All rights reserved.
//

import MultipeerConnectivity
import Cocoa

protocol MultipeerSessionDelegate {
    
    func connectedDevicesChanged(manager : MultipeerSession, connectedDevices: [String])
    func messageReceived(manager : MultipeerSession, message: Message, from:MCPeerID)
    
}

enum MessageType:Int {
    case ToProcess = 1
    case Processed = 2
    case Received = 3
    case Go = 4
}

struct Message: Codable {
    var peerHashID:Int
    var messageType:Int
    var messageOrder:[Int]
    var stringList:[String]?
    var timeElapsed:Double?
    var processedString:String?
}

/// - Tag: MultipeerSession
class MultipeerSession: NSObject {
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    static let serviceType = "everton-distrib"
    
    let myPeerID = MCPeerID(displayName: Host.current().localizedName!)
    
    var session:MCSession
    
    var advertiserAssistant: MCAdvertiserAssistant!
    
    var delegate : MultipeerSessionDelegate?
    
    /// - Tag: MultipeerSetup
    override init() {
        
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        
        self.session.delegate = self
    }
    
    // start hosting to peers
    func startHosting() {
        self.advertiserAssistant = MCAdvertiserAssistant(serviceType: MultipeerSession.serviceType, discoveryInfo: nil, session: self.session)
        self.advertiserAssistant.start()
    }
    
    // start hosting to peers
    func stopHosting() {
        if let advertiser = self.advertiserAssistant {
            advertiser.stop()
        }
    }
    
    // encodes the message to Data
    func encodeMessage(message:Message) -> Data {
        var encodedData = Data()
        
        let encoder = JSONEncoder()
        
        do {
            encodedData = try encoder.encode(message)
        } catch {
            print(error.localizedDescription)
        }
        
        return encodedData
    }
    
    // send the message to desired peer
    func send(dataToSend:Data, peerToSend:MCPeerID) {
        
        do {
            try self.session.send(dataToSend, toPeers: [peerToSend], with: .reliable)
        }
        catch {
            print("Could not send message to \(peerToSend.displayName)")
        }
    }
}

extension MultipeerSession: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: session.connectedPeers.map{$0.displayName})
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: session.connectedPeers.map{$0.displayName})
            
        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        let message = try! decoder.decode(Message.self, from: data)
        
        self.delegate?.messageReceived(manager: self, message: message, from: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
}

