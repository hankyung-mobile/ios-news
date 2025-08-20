//
//  SectionLIstViewCell.swift
//  newsApp
//
//  Created by jay on 7/3/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit

class SectionListViewCell: UITableViewCell {

    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbSubTitle: UILabel!
    @IBOutlet weak var lyImg: UIView!
    @IBOutlet weak var imgSection: UIImageView!
    @IBOutlet weak var lyDivider: UIView!
    
    // 이미지 로딩용 프로퍼티 추가
    private var imageTask: URLSessionDataTask?
    private var currentImageURL: String?
    
    private var overlayView: UIView?
    
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
//        imgSection.contentMode = .scaleToFill
        imgSection.contentMode = .scaleAspectFill
        imgSection.clipsToBounds = true
        imgSection.backgroundColor = UIColor.systemGray6
        
        // 이미지 컨테이너 설정
        lyImg.clipsToBounds = true
    }
    
    private func addOverlay() {
        // 기존 오버레이 제거
        overlayView?.removeFromSuperview()
        
        overlayView = UIView()
        overlayView?.backgroundColor = UIColor.clear
        overlayView?.isUserInteractionEnabled = false
        
        guard let overlay = overlayView else { return }
        
        imgSection.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: imgSection.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: imgSection.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: imgSection.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: imgSection.bottomAnchor)
        ])
        
        let borderWidth: CGFloat = 1.0
        let borderColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.08)
        
        // 상단 테두리 (전체 너비)
        let topBorder = UIView()
        topBorder.backgroundColor = borderColor
        overlay.addSubview(topBorder)
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: overlay.topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: borderWidth)
        ])
        
        // 하단 테두리 (전체 너비)
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = borderColor
        overlay.addSubview(bottomBorder)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomBorder.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
            bottomBorder.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: borderWidth)
        ])
        
        // 좌측 테두리 (상하 테두리 제외한 높이)
        let leftBorder = UIView()
        leftBorder.backgroundColor = borderColor
        overlay.addSubview(leftBorder)
        leftBorder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftBorder.topAnchor.constraint(equalTo: overlay.topAnchor, constant: borderWidth),
            leftBorder.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -borderWidth),
            leftBorder.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            leftBorder.widthAnchor.constraint(equalToConstant: borderWidth)
        ])
        
        // 우측 테두리 (상하 테두리 제외한 높이)
        let rightBorder = UIView()
        rightBorder.backgroundColor = borderColor
        overlay.addSubview(rightBorder)
        rightBorder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightBorder.topAnchor.constraint(equalTo: overlay.topAnchor, constant: borderWidth),
            rightBorder.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -borderWidth),
            rightBorder.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            rightBorder.widthAnchor.constraint(equalToConstant: borderWidth)
        ])
    }
    
    // MARK: - Image Loading (캐시 기능 추가)
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            imgSection.image = UIImage(named: "thumbnailPlaceHolder")
            self.imgSection.isTopAligned = false
            return
        }
        
        // 기존 다운로드 취소
        imageTask?.cancel()
        
        // 현재 URL 저장
        currentImageURL = urlString
        
        // 캐시에서 이미지 확인 - 추가된 부분
        let cacheKey = NSString(string: urlString)
        if let cachedImage = SectionListViewCell.imageCache.object(forKey: cacheKey) {
            // 캐시된 이미지 있으면 바로 설정 (다운로드 안 함!)
            imgSection.image = cachedImage
            self.imgSection.isTopAligned = true
            self.addOverlay()
            return
        }
        
        // 플레이스홀더 이미지 설정
        imgSection.image = UIImage(named: "thumbnailPlaceHolder")
        self.imgSection.isTopAligned = false
        
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
                SectionListViewCell.imageCache.setObject(image, forKey: cacheKey)
                
                // 이미지 설정 (페이드 애니메이션)
                UIView.transition(with: self.imgSection,
                                  duration: 0.5,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.imgSection.image = image
                }, completion: nil)
                self.imgSection.isTopAligned = true
                self.addOverlay()
            }
        }
        
        imageTask?.resume()
    }
    
    func configure(with item: NewsArticle) {
        lbTitle.text = item.title
        lbSubTitle.text = item.pubDate?.toDisplayFormat
        
        // 회원전용 기사
        if item.payment == "A" {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "typeMember")
            attachment.bounds = CGRect(x: 0, y: -2, width: 24, height: 24)
            
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
            attachment.bounds = CGRect(x: 0, y: -2, width: 24, height: 24)
            
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
    
    
    func configure(with item: PushItem) {
        lbTitle.text = item.message
        lbSubTitle.text = item.indate
        
        // 이미지 로딩
        if ((item.thumbimg?.isEmpty) == false) {
            lyImg.isHidden = false
            loadImage(from: item.thumbimg ?? "")
        } else {
            lyImg.isHidden = true
        }
    }
    
    func configure(with item: SearchResult) {
        lbTitle.text = item.title
        lbSubTitle.text = item.pubDate?.toDisplayFormat?.toDisplayFormat
        
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
    
    func configure(with item: AiSearchArticle) {
        lbTitle.text = item.title
        lbSubTitle.text = item.pubdate?.toDisplayFormat
          
        // 이미지 로딩
        if ((item.thumbnail?.isEmpty) == false) {
            lyImg.isHidden = false
            loadImage(from: item.thumbnail ?? "")
        } else {
            lyImg.isHidden = true
        }
    }
    
    
}
