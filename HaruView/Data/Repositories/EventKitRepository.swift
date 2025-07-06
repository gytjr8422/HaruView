//
//  EventKitRepository.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import Foundation
import EventKit

final class EventKitRepository: EventRepositoryProtocol, ReminderRepositoryProtocol {
    
    internal let service: EventKitService
    internal let cal = Calendar.current
    
    init(service: EventKitService = EventKitService()) {
        self.service = service
    }
}
