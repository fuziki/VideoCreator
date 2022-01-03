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
    private var connection: NWConnection?

    init(connectToRemote: Bool) {
        let host = connectToRemote ? "192.168.3.33" : "localhost"
        let parameters: NWParameters = .tcp
        parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolWebSocket.Options(), at: 0)
        connection = NWConnection(to: .url(URL(string: "ws://\(host):8080")!), using: parameters)
        connection?.stateUpdateHandler = { (state: NWConnection.State) in
            print("client state: \(state)")
        }
        connection?.start(queue: DispatchQueue.main)
    }

    public func send(message: Data) {
        if connection?.state != .ready {
            print("connection not ready: \(String(describing: connection?.state))")
            return
        }
        let metadata = NWProtocolWebSocket.Metadata(opcode: NWProtocolWebSocket.Opcode.binary)
        let context = NWConnection.ContentContext(identifier: "context",
                                                  metadata: [metadata])
        connection?.send(content: message,
                         contentContext: context,
                         isComplete: true,
                         completion: .contentProcessed({ e in print("e: \(String(describing: e))") }))
    }
}

class Server {
    public let onReceiveMessage: AnyPublisher<Data, Never>
    private let onReceiveMessageSubject = PassthroughSubject<Data, Never>()

    private var listener: NWListener!

    private var connections: [NWConnection] = []
    init() {
        onReceiveMessage = onReceiveMessageSubject.eraseToAnyPublisher()
        do {
            let parameters: NWParameters = .tcp
            parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolWebSocket.Options(), at: 0)
            listener = try NWListener(using: parameters, on: .init(rawValue: 8080)!)
        } catch let error {
            print("error: \(error)")
        }
        listener.newConnectionHandler = { [weak self] (connection: NWConnection) in
            self?.connections.append(connection)
            print("new connection: \(connection)")
            self?.sub(connection: connection)
            connection.start(queue: DispatchQueue(label: "hogehoge.fuga.hogegggggg.server.connection"))
        }
        listener.start(queue: DispatchQueue.main)
    }

    private func sub(connection: NWConnection) {
        connection.receiveMessage { [weak self] (completeContent: Data?,
                                                 contentContext: NWConnection.ContentContext?,
                                                 isComplete: Bool,
                                                 error: NWError?) in
            if let content = completeContent {
                self?.onReceiveMessageSubject.send(content)
            }
            if let error = error {
                print("error: \(error)")
            } else {
                self?.sub(connection: connection)
            }
        }
    }
}
