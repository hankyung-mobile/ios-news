//
//  MenuBannerTableViewCell.swift
//  newsApp
//
//  Created by jay on 8/8/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import Foundation

// MARK: - Extension for AppDataManager
extension AppDataManager {
    func getRandomBanner() -> Banner? {
        guard let banners = getMasterData()?.data?.banner,
              !banners.isEmpty else {
            return nil
        }
        return banners.randomElement()
    }
}

// MARK: - Cell Configuration
class MenuBannerTableViewCell: UITableViewCell {

    @IBOutlet weak var bannerImageView: UIImageView!
    
    private var currentImageTask: URLSessionDataTask?
    private var currentBannerURL: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupRandomBanner()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 재사용 시 이전 이미지 태스크 취소
        currentImageTask?.cancel()
        bannerImageView.image = nil
        currentBannerURL = nil
        
        // 새로운 랜덤 배너 설정
        setupRandomBanner()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            openBannerURL()
        }
    }
    
    private func openBannerURL() {
        guard let urlString = currentBannerURL,
              let url = URL(string: urlString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func setupRandomBanner() {
        guard let randomBanner = AppDataManager.shared.getRandomBanner() else {
            return
        }
        
        // URL 저장
        currentBannerURL = randomBanner.url
        
        // 이미지 로드
        loadBannerImage(from: randomBanner.imageUrl)
    }
    
    private func loadBannerImage(from urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            bannerImageView.image = UIImage(named: "placeholder") // 기본 이미지
            return
        }
        
        // 이전 작업 취소
        currentImageTask?.cancel()
        
        // 새로운 이미지 다운로드 작업
        currentImageTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let data = data,
                      error == nil,
                      let image = UIImage(data: data) else {
                    self?.bannerImageView.image = UIImage(named: "placeholder")
                    return
                }
                
                self.bannerImageView.image = image
            }
        }
        
        currentImageTask?.resume()
    }
}
