//
//  AlarmDTOs.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import Foundation

// MARK: - 알람 입력 DTO
struct AlarmInput: Identifiable {
    let type: AlarmType
    let trigger: AlarmTrigger
    
    var id: String {
        switch trigger {
        case .relative(let interval):
            return "relative_\(interval)"
        case .absolute(let date):
            return "absolute_\(date.timeIntervalSince1970)"
        }
    }
    
    enum AlarmType {
        case display, email, sound
    }
    
    enum AlarmTrigger {
        case relative(TimeInterval)  // 초 단위 (음수: 미리, 양수: 늦게)
        case absolute(Date)          // 절대 시간
        
        var timeInterval: TimeInterval? {
            if case .relative(let interval) = self {
                return interval
            }
            return nil
        }
        
        var absoluteDate: Date? {
            if case .absolute(let date) = self {
                return date
            }
            return nil
        }
    }
    
    var description: String {
        // languageManager의 refreshTrigger 의존성 생성
        let _ = LanguageManager.shared.refreshTrigger
        
        switch trigger {
        case .relative(let interval):
            if interval == 0 {
                return "이벤트 시간".localized()
            } else if interval < 0 {
                let minutes = Int(abs(interval) / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 전".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 전".localized(with: hours)
                } else {
                    return "%d분 전".localized(with: minutes)
                }
            } else {
                let minutes = Int(interval / 60)
                let hours = minutes / 60
                let days = hours / 24
                
                if days > 0 {
                    return "%d일 후".localized(with: days)
                } else if hours > 0 {
                    return "%d시간 후".localized(with: hours)
                } else {
                    return "%d분 후".localized(with: minutes)
                }
            }
        case .absolute(let date):
            let formatter = DateFormatterFactory.formatter(for: .dateTime)
            return formatter.string(from: date)
        }
    }
}

// MARK: - 사전 정의된 알람 설정
extension AlarmInput {
    static let presets: [AlarmInput] = [
        AlarmInput(type: .display, trigger: .relative(0)),           // 이벤트 시간
        AlarmInput(type: .display, trigger: .relative(-5 * 60)),     // 5분 전
        AlarmInput(type: .display, trigger: .relative(-15 * 60)),    // 15분 전
        AlarmInput(type: .display, trigger: .relative(-30 * 60)),    // 30분 전
        AlarmInput(type: .display, trigger: .relative(-60 * 60)),    // 1시간 전
        AlarmInput(type: .display, trigger: .relative(-2 * 60 * 60)), // 2시간 전
        AlarmInput(type: .display, trigger: .relative(-24 * 60 * 60)), // 1일 전
        AlarmInput(type: .display, trigger: .relative(-7 * 24 * 60 * 60)) // 1주일 전
    ]
}
