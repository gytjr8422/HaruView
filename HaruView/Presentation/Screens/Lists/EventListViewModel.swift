//
//  EventListViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/6/25.
//

import Foundation
import Combine
import SwiftUI
import EventKit

protocol EventListViewModelProtocol: ObservableObject {
    var events: [Event] { get }
    var showRecurringDeletionOptions: Bool { get set }
    var currentDeletingEvent: Event? { get }
    var isDeletingEvent: Bool { get }
    var deletionError: TodayBoardError? { get set }
    
    func load()
    func delete(id: String) async
    func refresh()
    func requestEventDeletion(_ event: Event)
    func deleteEventWithSpan(_ span: EventDeletionSpan)
    func cancelEventDeletion()
}

@MainActor
final class EventListViewModel: ObservableObject, @preconcurrency EventListViewModelProtocol {
    
    @Published var events: [Event] = []
    @Published var error: TodayBoardError?
    
    // MARK: - 삭제 UI 상태
    @Published var showRecurringDeletionOptions: Bool = false
    @Published var currentDeletingEvent: Event?
    @Published var isDeletingEvent: Bool = false
    @Published var deletionError: TodayBoardError?
    
    private let fetchToday: FetchTodayOverviewUseCase
    private let deleteObjectUseCase: DeleteObjectUseCase
    private var cancellables = Set<AnyCancellable>()
    
    init(fetchToday: FetchTodayOverviewUseCase, deleteObject: DeleteObjectUseCase) {
        self.fetchToday = fetchToday
        self.deleteObjectUseCase = deleteObject
    }
    
    func load() {
        Task {
            // 권한이 이미 부여된 상태인지 확인
            let hasPermissions = EKEventStore.authorizationStatus(for: .event) == .fullAccess &&
                               EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
            
            switch await fetchToday(skipPermissionCheck: hasPermissions) {
            case .success(let overview): self.events = overview.events
            case .failure(let error): self.error = error
            }
        }
    }
    
    func delete(id: String) async {
        if case .success = await deleteObjectUseCase(DeleteObjectUseCase.ObjectKind.event(id)) {
            events.removeAll { $0.id == id }
        }
    }
    
    func refresh() {
        self.load()
    }
    
    // MARK: - 스마트 삭제 메서드들
    
    /// 이벤트 삭제 요청 (스마트 삭제)
    func requestEventDeletion(_ event: Event) {
        currentDeletingEvent = event
        
        if event.hasRecurrence {
            // 반복 일정이면 옵션 선택 표시
            showRecurringDeletionOptions = true
        } else {
            // 일반 일정이면 바로 삭제
            Task {
                await deleteEvent(event.id, span: .thisEventOnly)
            }
        }
    }
    
    /// 선택된 범위로 이벤트 삭제
    func deleteEventWithSpan(_ span: EventDeletionSpan) {
        guard let event = currentDeletingEvent else { return }
        
        showRecurringDeletionOptions = false
        
        Task {
            await deleteEvent(event.id, span: span)
        }
    }
    
    /// 삭제 취소
    func cancelEventDeletion() {
        showRecurringDeletionOptions = false
        currentDeletingEvent = nil
    }
    
    /// 실제 삭제 실행
    private func deleteEvent(_ id: String, span: EventDeletionSpan) async {
        isDeletingEvent = true
        deletionError = nil
        
        let result = await deleteObjectUseCase(.eventWithSpan(id, span))
        
        await MainActor.run {
            isDeletingEvent = false
            
            switch result {
            case .success:
                currentDeletingEvent = nil
                // 로컬 리스트에서도 제거
                events.removeAll { $0.id == id }
                refresh() // 전체 새로고침으로 안전하게
            case .failure(let error):
                deletionError = error
            }
        }
    }
}
