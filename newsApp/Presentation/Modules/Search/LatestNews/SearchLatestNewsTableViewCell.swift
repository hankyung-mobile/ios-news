//
//  SearchLatestNewsTableViewCell.swift
//  newsApp
//
//  Created by jay on 7/25/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class SearchLatestNewsTableViewCell: UITableViewCell {
    @IBOutlet weak var lyImg: UIView!
    @IBOutlet weak var imgSection: UIImageView!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbSubTitle: UILabel!
    
    // 이미지 로딩용 프로퍼티 추가
    private var imageTask: URLSessionDataTask?
    private var currentImageURL: String?
    
    // 간단한 이미지 캐시 (클래스 레벨) - 추가된 부분
    private static let imageCache = NSCache<NSString, UIImage>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupImageView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 기존 데이터 초기화
        lbTitle.text = nil
        lbSubTitle.text = nil
        imgSection.image = nil
        
        // 이미지 다운로드 취소
        imageTask?.cancel()
        imageTask = nil
        currentImageURL = nil
    }
    
    static func clearCache() {
        imageCache.removeAllObjects()
    }
    
    private func setupImageView() {
        // 이미지뷰 기본 설정
        imgSection.contentMode = .scaleToFill
//        imgSection.contentMode = .scaleAspectFit
        imgSection.clipsToBounds = true
        imgSection.backgroundColor = UIColor.systemGray6
        
        // 이미지 컨테이너 설정
        lyImg.clipsToBounds = true
    }
    
    func configure(with item: SearchResult) {
        lbTitle.text = item.title
        lbSubTitle.text = item.pubDate
        
        // 회원전용 기사
        if item.payment == "A" {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "typeMember")
            attachment.bounds = CGRect(x: 0, y: -2, width: 36, height: 23)
            
            let attributedString = NSMutableAttributedString(attachment: attachment)
            let spaceString = NSMutableAttributedString(string: " ")
            spaceString.addAttribute(.kern, value: 6, range: NSRange(location: 0, length: 1))
            attributedString.append(spaceString)
            attributedString.append(NSAttributedString(string: item.title ?? ""))
            
            lbTitle.attributedText = attributedString
        }
        
        // 유료기사
        if item.payment == "Y" {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "typePremium")
            attachment.bounds = CGRect(x: 0, y: -2, width: 26, height: 23)
            
            let attributedString = NSMutableAttributedString(attachment: attachment)
            let spaceString = NSMutableAttributedString(string: " ")
            spaceString.addAttribute(.kern, value: 6, range: NSRange(location: 0, length: 1))
            attributedString.append(spaceString)
            attributedString.append(NSAttributedString(string: item.title ?? ""))
            
            lbTitle.attributedText = attributedString
        }
        
        
        
        // 이미지 로딩
        if ((item.thumbimg?.isEmpty) == false) {
            lyImg.isHidden = false
            loadImage(from: item.thumbimg ?? "")
        } else {
            lyImg.isHidden = true
        }
    }
    
    // MARK: - Image Loading (캐시 기능 추가)
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            imgSection.image = UIImage(named: "thumbnailPlaceHolder")
            return
        }
        
        // 기존 다운로드 취소
        imageTask?.cancel()
        
        // 현재 URL 저장
        currentImageURL = urlString
        
        // 캐시에서 이미지 확인 - 추가된 부분
        let cacheKey = NSString(string: urlString)
        if let cachedImage = SearchLatestNewsTableViewCell.imageCache.object(forKey: cacheKey) {
            // 캐시된 이미지 있으면 바로 설정 (다운로드 안 함!)
            imgSection.image = cachedImage
            return
        }
        
        // 플레이스홀더 이미지 설정
        imgSection.image = UIImage(named: "thumbnailPlaceHolder")
        
        // 이미지 다운로드
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // 현재 셀이 여전히 같은 URL을 로딩하는지 확인
                guard let self = self,
                      self.currentImageURL == urlString,
                      let data = data,
                      let image = UIImage(data: data) else {
                    return
                }
                
                // 캐시에 이미지 저장 - 추가된 부분
                SearchLatestNewsTableViewCell.imageCache.setObject(image, forKey: cacheKey)
                
                // 이미지 설정 (페이드 애니메이션)
                UIView.transition(with: self.imgSection,
                                  duration: 0.5,
                                options: .transitionCrossDissolve,
                                animations: {
                    self.imgSection.image = image
                }, completion: nil)
            }
        }
        
        imageTask?.resume()
    }
}
