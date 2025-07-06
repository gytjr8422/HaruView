//
//  ReminderUseCases.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

/// 미리알림 추가 유스케이스
struct AddReminderUseCase {
    private let repo: ReminderRepositoryProtocol
    
    init(repo: ReminderRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ input: ReminderInput) async -> Result<Void, TodayBoardError> {
        await repo.add(input)
    }
}

/// 미리알림 수정 유스케이스
struct EditReminderUseCase {
    private let repo: ReminderRepositoryProtocol

    init(repo: ReminderRepositoryProtocol) {
        self.repo = repo
    }

    func callAsFunction(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError> {
        await repo.update(edit)
    }
}

struct ToggleReminderUseCase {
    private let repo: ReminderRepositoryProtocol
    
    init(repo: ReminderRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ id: String) async -> Result<Void, TodayBoardError> {
        await repo.toggle(id: id)
    }
}

