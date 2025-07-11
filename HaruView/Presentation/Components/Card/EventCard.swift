//
//  EventCard.swift
//  HaruView
//
//  Created by 김효석 on 5/14/25.
//

import SwiftUI

struct EventCard: View {
    let event: Event
    private var isPast: Bool { event.end < Date() }
    
    var body: some View {
        HStack {
            Text(event.title)
                .lineLimit(1)
                .font(.pretendardSemiBold(size: 17))
                .foregroundStyle(Color(hexCode: "40392B"))
                .strikethrough(isPast)
                .opacity(isPast ? 0.5 : 1)
            
            Spacer()
            
            // 조건부로 시간 표시
            if let timeText {
                Text(timeText)
                    .lineLimit(1)
                    .font(.jakartaRegular(size: 15))
                    .foregroundStyle(Color(hexCode: "2E2514").opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hexCode: "FFFCF5"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
        )
        
    }
    
    /// 세 가지 조건에 따라 출력할 문자열을 반환
    private var timeText: String? {
        let start = event.start
        let end   = event.end
        let startStr = formatted(start)
        let endStr   = formatted(end)
        
        // 1) 하루 종일 이벤트 (00:00–23:59) 감지
        let compsStart = Calendar.current.dateComponents([.hour, .minute], from: start)
        let compsEnd   = Calendar.current.dateComponents([.hour, .minute], from: end)
        let isFullDay = compsStart.hour == 0 && compsStart.minute == 0
                     && compsEnd.hour   == 23 && compsEnd.minute   == 59
        if isFullDay {
            return nil
        }
        
        // 2) 시작 == 종료 (분 단위) → 한 번만 표시
        if Calendar.current.isDate(start, equalTo: end, toGranularity: .minute) {
            return startStr
        }
        
        // 3) 그 외 → "시작 – 종료"
        return "\(startStr) - \(endStr)"
    }
    
    private func formatted(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
}
