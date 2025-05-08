//
//  EventListViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/6/25.
//

import Foundation

protocol EventListViewModelProtocol: ObservableObject {
    var events: [Event] { get }
    func load()
    func delete(id: String)
    func refresh()
}

@MainActor
final class EventListViewModel: ObservableObject, @preconcurrency EventListViewModelProtocol {
    
    @Published var events: [Event] = []
    @Published var error: TodayBoardError?
    
    private let repo: EventRepositoryProtocol?
    
    init(repo: EventRepositoryProtocol) {
        self.repo = repo
    }
    
    func load() {
        guard let repo else { return }
        Task {
            switch await repo.fetchEvent() {
            case .success(let events): self.events = events
            case .failure(let error): self.error = error
            }
        }
    }
    
    func delete(id: String) {
        if let repo {
            Task {
                if case .success = await repo.deleteEvent(id: id) {
                    events.removeAll { $0.id == id }
                }
            }
        }
    }
    
    func refresh() {
        self.load()
    }
}
