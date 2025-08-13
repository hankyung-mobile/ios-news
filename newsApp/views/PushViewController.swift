//
//  PushViewController.swift
//  newsApp
//
//  Created by hkcom on 2020/09/21.
//  Copyright © 2020 hkcom. All rights reserved.
//

import Foundation
import UIKit

class PushViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var pushNewsDateList: [String] = []
    var pushNewsList: [String:[PushNews]] = [:] {
        didSet {
            guard pushNewsList.count > 0 else {
                return
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var newsArticleUrl: String = ""
    var newsArticleViewTitle: String = "뉴스"
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getPushNewsListData()
    }
    
    override func viewDidLayoutSubviews() {

    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {

    }
    
    override func viewDidDisappear(_ animated: Bool) {

    }
    
    
    func getPushNewsListData() {
        
        guard let url:URL = URL(string: "\(SITEURL)/app-data/push/newsList") else {
            return
        }
        var request:URLRequest = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = apiHeader
        
        let IPTask = URLSession.shared.dataTask(with: request) { (data, res, err) in
            
            guard let httpResponse = res as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            if err != nil || data == nil { return }
            
            do {
                let pushNewsList: [String:[PushNews]] = try JSONDecoder().decode([String:[PushNews]].self, from: data!)
                self.pushNewsDateList = pushNewsList.keys.sorted(by: >)
                self.pushNewsList = pushNewsList
                
            } catch let error {
                print(error.localizedDescription)
                
            }
        }
        
        IPTask.resume()
    }
    
    func openArticleView(url: String, media: String) {
        self.newsArticleUrl = url
        self.newsArticleViewTitle = media
        
        self.performSegue(withIdentifier: "newsArticleViewSegue", sender: self)
    }
    
}

extension PushViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return pushNewsDateList.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pushNewsList[pushNewsDateList[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dateHeader") as! PushNewsViewDateHeader
        
        cell.date.text = pushNewsDateList[section]
        
        return cell.contentView
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 95
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard pushNewsDateList.count > 0 else {
            return UITableViewCell()
        }

        let key = self.pushNewsDateList[indexPath.section] as String
        
        guard let pushNewsList = self.pushNewsList[key] else {
            return UITableViewCell()
        }
        
        let pushNews = pushNewsList[indexPath.row]
        

        let cell = tableView.dequeueReusableCell(withIdentifier: "basiccell", for: indexPath) as! PushNewsViewBasicCell
        
        cell.time.text = pushNews.reservedtime
        
        if pushNews.url == "" {
            cell.time.textColor = .none
        }
        else {
            cell.time.textColor = UIColor.systemBlue
        }
        
        cell.title.text = pushNews.message
        
        if(pushNews.type == "") {
            cell.subtitle.isHidden = true
        }
        else {
            cell.subtitle.isHidden = false
            cell.subtitle.text = pushNews.type
        }
        
        cell.topLine.isHidden = false
        cell.bottomLine.isHidden = false

        if indexPath.row == 0 {
            cell.topLine.isHidden = true
        }
   
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let key = self.pushNewsDateList[indexPath.section] as String
        
        
        guard let pushNews = self.pushNewsList[key]?[indexPath.row] else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        guard pushNews.url != "" else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        self.newsArticleUrl = pushNews.url
        self.newsArticleViewTitle = pushNews.viewMediaTitle
        
        self.performSegue(withIdentifier: "newsArticleViewSegue", sender: self)
        
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination
        
        guard let anvc = dest as? UINavigationController, let avc = anvc.topViewController as? NewsArticlViewViewController else {
            return
        }
        
        avc.url = self.newsArticleUrl
        avc.viewTitleText = self.newsArticleViewTitle

    }
}






class PushNewsViewBasicCell: UITableViewCell {
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var topLine: UIView!
    @IBOutlet weak var dot: UIView!
    @IBOutlet weak var bottomLine: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        dot.layer.cornerRadius = 3.5
        dot.clipsToBounds = true
    }
}

class PushNewsViewDateHeader: UITableViewCell {
    @IBOutlet weak var date: UILabel!
}

struct PushNews: Decodable {
    var indate: String
    var reservedtime: String
    var message: String
    var type: String
    var url: String
    var audio: String
    var viewMedia: String
    var viewMediaTitle: String
}
