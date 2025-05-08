//
//  HomeState.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import Foundation

// MARK: - UI State

struct HomeState: Equatable {
    var overview: TodayOverview = .placeholder
    var isLoading: Bool = false
    var error: TodayBoardError? = nil
}
