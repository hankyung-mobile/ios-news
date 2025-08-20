//
//  TermSearchManager.swift
//  newsApp
//
//  Created by jay on 8/18/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

class TermSearchManager {
    static let shared = TermSearchManager()
    
    private let userDefaults = UserDefaults.standard
    private let recentNewsKey = "TermSearch"
    private let maxCount = 10
    
    private init() {}
    
    // MARK: - 뉴스 저장
    func saveRecentNews(_ searchResult: TermItem) {
        var recentNewsList = getRecentNewsList()
        
        // 이미 존재하는 항목인지 확인 (aid로 중복 체크)
        if let existingIndex = recentNewsList.firstIndex(where: { $0.seq == searchResult.seq }) {
            // 기존 항목 제거
            recentNewsList.remove(at: existingIndex)
        }
        
        // 새 항목을 맨 앞에 추가
        recentNewsList.insert(searchResult, at: 0)
        
        // 10개 초과시 마지막 항목 제거 (FIFO)
        if recentNewsList.count > maxCount {
            recentNewsList = Array(recentNewsList.prefix(maxCount))
        }
        
        // UserDefaults에 저장
        saveToUserDefaults(recentNewsList)
        
        print("📚 최근 본 뉴스 저장 완료. 현재 \(recentNewsList.count)개")
    }
    
    // MARK: - 뉴스 목록 가져오기
    func getRecentNewsList() -> [TermItem] {
        guard let data = userDefaults.data(forKey: recentNewsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let recentNewsList = try decoder.decode([TermItem].self, from: data)
            return recentNewsList
        } catch {
            print("❌ 최근 본 뉴스 디코딩 실패: \(error)")
            return []
        }
    }
    
    // MARK: - 특정 뉴스 삭제
    func removeRecentNews(usernumber: Int) {
        var recentNewsList = getRecentNewsList()
        recentNewsList.removeAll { $0.seq == usernumber }
        saveToUserDefaults(recentNewsList)
    }
    
    // MARK: - 전체 삭제
    func clearAllRecentNews() {
        userDefaults.removeObject(forKey: recentNewsKey)
        print("📚 최근 본 뉴스 전체 삭제")
    }
    
    // MARK: - UserDefaults에 저장
    private func saveToUserDefaults(_ newsList: [TermItem]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(newsList)
            userDefaults.set(data, forKey: recentNewsKey)
            userDefaults.synchronize()
        } catch {
            print("❌ 최근 본 뉴스 저장 실패: \(error)")
        }
    }
    
    // MARK: - 디버깅용 출력
    func printRecentNews() {
        let recentNewsList = getRecentNewsList()
        print("📚 최근 본 뉴스 목록 (\(recentNewsList.count)개):")
        for (index, news) in recentNewsList.enumerated() {
            print("\(index + 1). \(news.word ?? "제목 없음") - \(news.seq ?? 0)")
        }
    }
}


