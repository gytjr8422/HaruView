//
//  EventUseCases.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

/// 일정 추가 유스케이스
struct AddEventUseCase {
    private let repo: EventRepositoryProtocol
    
    init(repo: EventRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ input: EventInput) async -> Result<Void, TodayBoardError> {
        await repo.add(input)
    }
}

/// 일정 수정 유스케이스
struct EditEventUseCase {
    private let repo: EventRepositoryProtocol
    
    init(repo: EventRepositoryProtocol) {
        self.repo = repo
    }
    
    func callAsFunction(_ edit: EventEdit) async -> Result<Void, TodayBoardError> {
        await repo.update(edit)
    }
}
