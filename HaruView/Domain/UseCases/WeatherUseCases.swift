//
//  WeatherUseCases.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//


struct FetchTodayWeatherUseCase {
    private let repo: WeatherRepositoryProtocol
    
    init(repo: WeatherRepositoryProtocol) { self.repo = repo }

    func callAsFunction() async -> Result<TodayWeather, TodayBoardError> {
        await repo.fetchWeather()
    }
}
