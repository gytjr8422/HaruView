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
    
    private let fetchToday: FetchTodayOverviewUseCase
    private let deleteObject: DeleteObjectUseCase
    
    init(fetchToday: FetchTodayOverviewUseCase, deleteObject: DeleteObjectUseCase) {
        self.fetchToday = fetchToday
        self.deleteObject = deleteObject
    }
    
    func load() {
        Task {
            switch await fetchToday() {
            case .success(let overview): self.events = overview.events
            case .failure(let error): self.error = error
            }
        }
    }
    
    func delete(id: String) {
        Task {
            if case .success = await deleteObject(DeleteObjectUseCase.ObjectKind.event(id)) {
                events.removeAll { $0.id == id }
            }
        }
    }
    
    func refresh() {
        self.load()
    }
}
