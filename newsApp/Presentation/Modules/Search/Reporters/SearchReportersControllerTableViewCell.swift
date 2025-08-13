//
//  SearchReportersControllerTableViewCell.swift
//  newsApp
//
//  Created by jay on 7/25/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class SearchReportersControllerTableViewCell: UITableViewCell {

    @IBOutlet weak var imgReporter: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    
    // 이미지 로딩용 프로퍼티 추가
    private var imageTask: URLSessionDataTask?
    private var currentImageURL: String?
    
    // 간단한 이미지 캐시 (클래스 레벨) - 추가된 부분
    private static let imageCache = NSCache<NSString, UIImage>()
    
    
    // MARK: - Properties
    override var isSelected: Bool {
        didSet {
//            updateSelectionState()
        }
    }
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 셀 재사용 시 초기화
        
        imageTask?.cancel()
        imageTask = nil
        currentImageURL = nil
        
        lbName.text = nil
        imgReporter.image = UIImage(named: "avatarHk")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // 셀 기본 스타일 설정
//        layer.cornerRadius = 8
//        layer.masksToBounds = true
//        backgroundColor = UIColor.systemBackground
//
//        // 선택 효과를 위한 설정
//        layer.borderWidth = 2
//        layer.borderColor = UIColor.clear.cgColor
        imgReporter.layer.cornerRadius = 28
        imgReporter.clipsToBounds = true
        imgReporter.contentMode = .scaleAspectFill
       
    }
    
    // MARK: - Configuration
    func configure(with item: ReporterItem) {
        lbName.text = item.name
        
        // 이미지 로딩
        if ((item.photo?.isEmpty) == false) {
            loadImage(from: item.photo ?? "")
        }
    }
    
    // MARK: - Image Loading (캐시 기능 추가)
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            imgReporter.image = UIImage(named: "avatarHk")
            return
        }
        
        // 기존 다운로드 취소
        imageTask?.cancel()
        
        // 현재 URL 저장
        currentImageURL = urlString
        
        // 캐시에서 이미지 확인 - 추가된 부분
        let cacheKey = NSString(string: urlString)
        if let cachedImage = SearchReportersControllerTableViewCell.imageCache.object(forKey: cacheKey) {
            // 캐시된 이미지 있으면 바로 설정 (다운로드 안 함!)
            imgReporter.image = cachedImage
            return
        }
        
        // 플레이스홀더 이미지 설정
        imgReporter.image = UIImage(named: "avatarHk")
        
        // 이미지 다운로드
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // URL 검증 강화
                guard let self = self,
                      self.currentImageURL == urlString, // 같은 URL인지 확인
                      !urlString.isEmpty,
                      let data = data,
                      let image = UIImage(data: data) else {
                    return
                }
                
                // 캐시에 저장
                SearchReportersControllerTableViewCell.imageCache.setObject(image, forKey: cacheKey)
                
                // 이미지 설정
                UIView.transition(with: self.imgReporter,
                                  duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    self.imgReporter.image = image
                }, completion: nil)
            }
        }
        
        imageTask?.resume()
    }
}
