//
//  WebSocket.swift
//  NativeExamples
//
//  Created by fuziki on 2022/01/03.
//

import Combine
import Foundation
import Network

class Client {
    private let connection: NWConnection

    init(url: String) {
        let parameters: NWParameters = .tcp
        parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolWebSocket.Options(), at: 0)
        connection = NWConnection(to: .url(URL(string: url)!), using: parameters)
        connection.stateUpdateHandler = { (state: NWConnection.State) in
            print("client state: \(state)")
        }
        connection.start(queue: DispatchQueue.main)
    }

    public func send(message: Data) {
        if connection.state != .ready {
            print("connection not ready: \(String(describing: connection.state))")
            return
        }
        let metadata = NWProtocolWebSocket.Metadata(opcode: NWProtocolWebSocket.Opcode.binary)
        let context = NWConnection.ContentContext(identifier: "context",
                                                  metadata: [metadata])
        connection.send(content: message,
                        contentContext: context,
                        isComplete: true,
                        completion: .contentProcessed({ e in print("e: \(String(describing: e))") }))
    }
}
