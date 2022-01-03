//
//  ControlPanelView.swift
//  NativeExamples
//
//  Created by fuziki on 2022/01/01.
//

import Combine
import Foundation
import SwiftUI

struct ControlPanelEntity: Codable {
    let clientLocal: Bool
    let clientRemote: Bool
    let server: Bool
    static var defaultValue: ControlPanelEntity {
        return .init(clientLocal: true, clientRemote: false, server: true)
    }
}

struct ControlPanelView: View {
    @ObservedObject var viewModel: ControlPanelViewModel
    init(viewModel: ControlPanelViewModel) {
        self.viewModel = viewModel
    }
    var body: some View {
        HStack {
            VStack {
                Text("Client(local)")
                Toggle("", isOn: $viewModel.clientLocal)
                    .labelsHidden()
            }
            Spacer()
            VStack {
                Text("Client(remote)")
                Toggle("", isOn: $viewModel.clientRemote)
                    .labelsHidden()
            }
            Spacer()
            VStack {
                Text("Server")
                Toggle("", isOn: $viewModel.server)
                    .labelsHidden()
            }
        }
        .padding(.horizontal, 16)
    }
}

class ControlPanelViewModel: ObservableObject {
    @Published var clientLocal: Bool
    @Published var clientRemote: Bool
    @Published var server: Bool
    public let config: AnyPublisher<ControlPanelEntity, Never>
    private let configSubject: CurrentValueSubject<ControlPanelEntity, Never>

    private let key = "ControlPanelViewModel.key"
    
    private var cancellables: Set<AnyCancellable> = []
    init() {
        let data = UserDefaults.standard.data(forKey: key)
        let entity = data.flatMap { try? JSONDecoder().decode(ControlPanelEntity.self, from: $0) } ?? .defaultValue
        configSubject = .init(entity)
        config = configSubject.eraseToAnyPublisher()
        clientLocal = entity.clientLocal
        clientRemote = entity.clientRemote
        server = entity.server
        setup()
    }
    
    private func setup() {
        $clientLocal.removeDuplicates().sink { [weak self] (clientLocal: Bool) in
            guard let self = self else { return }
            let now = self.configSubject.value
            let clientRemote = clientLocal ? false : now.clientRemote
            let new = ControlPanelEntity(clientLocal: clientLocal, clientRemote: clientRemote, server: now.server)
            self.update(new: new)
        }.store(in: &cancellables)

        $clientRemote.removeDuplicates().sink { [weak self] (clientRemote: Bool) in
            guard let self = self else { return }
            let now = self.configSubject.value
            let clientLocal = clientRemote ? false : now.clientLocal
            let new = ControlPanelEntity(clientLocal: clientLocal, clientRemote: clientRemote, server: now.server)
            self.update(new: new)
        }.store(in: &cancellables)

        $server.removeDuplicates().sink { [weak self] (server: Bool) in
            guard let self = self else { return }
            let now = self.configSubject.value
            let new = ControlPanelEntity(clientLocal: now.clientLocal, clientRemote: now.clientRemote, server: server)
            self.update(new: new)
        }.store(in: &cancellables)
    }
    
    private func update(new entity: ControlPanelEntity) {
        clientLocal = entity.clientLocal
        clientRemote = entity.clientRemote
        server = entity.server
        configSubject.send(entity)
        UserDefaults.standard.set(try! JSONEncoder().encode(entity), forKey: key)
    }
}

struct ControlPanelView_Previews: PreviewProvider {
    static var previews: some View {
        ControlPanelView(viewModel: ControlPanelViewModel())
            .previewLayout(.sizeThatFits)
    }
}
