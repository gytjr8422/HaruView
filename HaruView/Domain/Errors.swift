//
//  Errors.swift
//  HaruView
//
//  Created by 김효석 on 4/30/25.
//

import Foundation

/// 공통 에러 케이스
enum TodayBoardError: Error, Equatable {
    case accessDenied   // 권한 거부 (EventKit 등)
    case notFound       // 식별자에 해당 객체 없음
    case invalidInput   // DTO 검증 실패
    case saveFailed     // 저장, 업데이트 실패
    case networkError   // 날씨 API 등 네트워크 오류
    case system(String) // 기타 시스템 오류 메시지 래핑
    
    var description: String {
        switch self {
        case .accessDenied:
            "권한이 필요합니다."
        case .notFound:
            "찾을 수 없습니다."
        case .invalidInput:
            "올바른 입력이 아닙니다."
        case .saveFailed:
            "저장이나 업데이트에 실패했습니다."
        case .networkError:
            "네트워크에 문제가 있습니다."
        case .system(let message):
            "\(message)"
        }
    }
}

enum NetworkError: Error {
    case urlError
    case invalidResponse
    case failToDecode(String)
    case dataNil
    case serverError(Int)
    case requestFailed(String)
    
    var description: String {
        switch self {
        case .urlError:
            "URL이 올바르지 않습니다"
        case .invalidResponse:
            "응닶값이 유효하지 않습니다"
        case .failToDecode(let description):
            "디코딩 에러 \(description)"
        case .dataNil:
            "데이터가 없습니다"
        case .serverError(let statusCode):
            "서버에러 \(statusCode)"
        case .requestFailed(let message):
            "서벼 요청 실패 \(message)"
        }
    }
}
