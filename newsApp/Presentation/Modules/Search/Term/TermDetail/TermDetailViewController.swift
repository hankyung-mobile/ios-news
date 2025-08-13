//
//  TermDetailViewController.swift
//  newsApp
//
//  Created by jay on 7/29/25.
//  Copyright © 2025 hkcom. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TermDetailViewController: UIViewController {

    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbSubTitle: UILabel!
    
    private let viewModel = TermDetailViewModel()
    private let disposeBag = DisposeBag()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    @IBOutlet weak var btnClose: UIButton!
    var seq: Int = 0 // 이전 화면에서 전달받을 seq
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
         setupUI()
         setupBindings()
         setupButtonEvents()
         loadData()
     }
     
     private func setupUI() {
         // 인디케이터 설정
         activityIndicator.translatesAutoresizingMaskIntoConstraints = false
         activityIndicator.hidesWhenStopped = true
         activityIndicator.color = .gray
         
         view.addSubview(activityIndicator)
         
         // 인디케이터 중앙 배치
         NSLayoutConstraint.activate([
             activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
         ])
         
         // 네비게이션 바에 새로고침 버튼 추가 (옵션)
         navigationItem.rightBarButtonItem = UIBarButtonItem(
             barButtonSystemItem: .refresh,
             target: self,
             action: #selector(refresh)
         )
         
         let fontSize = UIFont.preferredFont(forTextStyle: .title3).pointSize
         let boldFont = UIFont.boldSystemFont(ofSize: fontSize)
         
         lbTitle.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: boldFont)
         lbTitle.adjustsFontForContentSizeCategory = true
     }
     
     private func setupBindings() {
         // 로딩 상태
         viewModel.isLoading
             .bind { [weak self] isLoading in
                 if isLoading {
                     self?.showLoading()
                 } else {
                     self?.hideLoading()
                 }
             }
             .disposed(by: disposeBag)
         
         // 데이터 바인딩
         viewModel.items
             .bind { [weak self] items in
                 if let item = items.first {
                     self?.lbTitle.text = item.word
                     self?.lbSubTitle.text = item.content
                 } else {
                     self?.lbTitle.text = ""
                     self?.lbSubTitle.text = "데이터가 없습니다."
                 }
             }
             .disposed(by: disposeBag)
         
         // 에러 처리
         viewModel.error
             .bind { [weak self] errorMessage in
                 self?.showError(errorMessage)
             }
             .disposed(by: disposeBag)
     }
    
    private func setupButtonEvents() {

        btnClose.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                // 네비게이션 컨트롤러가 있고 루트가 아닌 경우 pop
                if let navigationController = self?.navigationController,
                   navigationController.viewControllers.count > 1 {
                    navigationController.popViewController(animated: true)
                } else {
                    // 모달로 표시된 경우 dismiss
                    self?.dismiss(animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }

     
     private func loadData() {
         viewModel.search(seq: seq)
     }
     
     // 새로고침
     @objc private func refresh() {
         viewModel.refresh(seq: seq)
     }
     
     // 로딩 표시
     private func showLoading() {
         activityIndicator.startAnimating()
         
         // 로딩 중 레이블 숨기기 (옵션)
         lbTitle.isHidden = true
         lbSubTitle.isHidden = true
     }
     
     private func hideLoading() {
         activityIndicator.stopAnimating()
         
         // 레이블 다시 표시
         lbTitle.isHidden = false
         lbSubTitle.isHidden = false
     }
     
     private func showError(_ message: String) {
         // 에러 알림 표시
         let alert = UIAlertController(
             title: "오류",
             message: message,
             preferredStyle: .alert
         )
         
         alert.addAction(UIAlertAction(title: "확인", style: .default))
         
         // 재시도 옵션 추가
         alert.addAction(UIAlertAction(title: "재시도", style: .default) { [weak self] _ in
             self?.loadData()
         })
         
         present(alert, animated: true)
     }
 }
