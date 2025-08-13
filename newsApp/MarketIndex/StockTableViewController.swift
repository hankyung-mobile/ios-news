//
//  TableViewController.swift
//  newsApp
//
//  Created by hkcom on 2020/08/27.
//  Copyright © 2020 hkcom. All rights reserved.
//

import UIKit

class StockTableViewController: UITableViewController {
    
    var stockDataUpdateScheduledTimer: Timer? = nil
    var indexData: [StockIndexData] = []
//    var indexData: [StockIndexData] = [] {
//        didSet {
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
//        }
//    }
    
    var newsData: [StockNewsData] = []
    var investorsData: [StockInvestorsData] = []
    
    var newsArticleUrl: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.getAllData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.createScheduledTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.removeScheduledTimer()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if indexData.count == 0 {
            return 0
        }
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.indexData.count
        case 1:
            return self.investorsData.count + 1
        case 2:
            return self.newsData.count
        default:
            return 0
        }
        
    }
    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        
//        switch section {
//        case 0:
//            return "증권"
//        case 1:
//            return "투자자동향"
//        case 2:
//            return "증권속보"
//        default:
//            return ""
//        }
//    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "indexHeader")
        
        switch section {
        case 0:
            return nil//tableView.dequeueReusableCell(withIdentifier: "indexHeader")?.contentView
        case 1:
            return tableView.dequeueReusableCell(withIdentifier: "investorsHeader")?.contentView
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "newsHeader") as! StockNewsSectionHeader
            
            cell.newsReloadButton.addTarget(self, action: #selector(newsDataReload), for: .touchUpInside)
            
            return cell.contentView//tableView.dequeueReusableCell(withIdentifier: "newsHeader")?.contentView
        default:
            return nil
        }
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        switch section {
        case 0:
            return 35
        default:
            return 72
        }

    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            var cellName: String = "indexCell"
            
            if UI_USER_INTERFACE_IDIOM() == .pad {
                cellName = "padIndexCell"
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath) as! StockIndexTableCell
            
            let data: StockIndexData = indexData[indexPath.row]
            
            cell.name.text = data.종목명
            cell.date.text = data.거래일자
            cell.price.text = data.종가
            cell.netChange.text = "\(data.전일대비) \(data.대비부호)\(data.등락률)%"
            
            if data.대비부호 == "-" {
                cell.netChange.textColor = UIColor(rgb: 0x1976D2)
            } else if data.대비부호 == "+" {
                cell.netChange.textColor = UIColor(rgb: 0xF44336)
            } else {
                cell.netChange.textColor = UIColor(rgb: 0x666666)
            }
            
            return cell
        }
        else if indexPath.section == 1 {
            
            if indexPath.row == 0 {
                return tableView.dequeueReusableCell(withIdentifier: "investorsTitleCell", for: indexPath)
            }
  
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "investorsCell", for: indexPath) as! StockInvestorsTableCell
            
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
            
            
            let data: StockInvestorsData = investorsData[indexPath.row - 1]
            
            cell.name.text = data.지수
            cell.individualPrice.text = data.개인
            cell.foreignerPrice.text = data.외국인
            cell.organizationPrice.text = data.기관
            
            
            if data.개인.contains("-") {
                cell.individualPrice.textColor = UIColor(rgb: 0x1976D2)
            } else if data.개인 == "0" {
                cell.individualPrice.textColor = UIColor(rgb: 0x666666)
            } else {
                cell.individualPrice.textColor = UIColor(rgb: 0xF44336)
            }
            
            
            if data.외국인.contains("-") {
                cell.foreignerPrice.textColor = UIColor(rgb: 0x1976D2)
            } else if data.외국인 == "0" {
                cell.foreignerPrice.textColor = UIColor(rgb: 0x666666)
            } else {
                cell.foreignerPrice.textColor = UIColor(rgb: 0xF44336)
            }
            
            if data.기관.contains("-") {
                cell.organizationPrice.textColor = UIColor(rgb: 0x1976D2)
            } else if data.기관 == "0" {
                cell.organizationPrice.textColor = UIColor(rgb: 0x666666)
            } else {
                cell.organizationPrice.textColor = UIColor(rgb: 0xF44336)
            }
            
            return cell
        }
        else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! StockNewsTableCell
            
//            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
            
            let data: StockNewsData = self.newsData[indexPath.row]
            
            cell.title.text = data.title
            
            return cell
        }
        

        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
        guard indexPath.section == 2 else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let news = self.newsData[indexPath.row]

        self.newsArticleUrl = news.url
        
        self.performSegue(withIdentifier: "newsArticleViewSegue", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination

        guard let anvc = dest as? UINavigationController, let avc = anvc.topViewController as? NewsArticlViewViewController else {
            return
        }
        
        avc.url = self.newsArticleUrl
        avc.viewTitleText = "증권 뉴스"
    }
}

extension StockTableViewController {
    
    func getAllData() {
        guard let url:URL = URL(string: "\(SITEURL)/app-data/stock/all") else {
            return
        }
        
        marketIndexViewController?.activityIndicator.startAnimating()
        
        var request:URLRequest = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = apiHeader
        
        let IPTask = URLSession.shared.dataTask(with: request) { (data, res, err) in
            
            guard let httpResponse = res as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            if err != nil || data == nil { return }
            
            do {
                let allData: StockAllData = try JSONDecoder().decode(StockAllData.self, from: data!)
                
                self.newsData = allData.news ?? []
                self.investorsData = allData.investors
                self.indexData = allData.index
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    marketIndexViewController?.activityIndicator.stopAnimating()
                }
                 
                
            } catch let error {
                DispatchQueue.main.async {
                    marketIndexViewController?.activityIndicator.stopAnimating()
                }
                print(error.localizedDescription)
            }
        }
        
        IPTask.resume()
    }
    
    func getIndexData() {
        guard let url:URL = URL(string: "\(SITEURL)/app-data/stock/indexList") else {
            return
        }
        var request:URLRequest = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = apiHeader
        
        let IPTask = URLSession.shared.dataTask(with: request) { (data, res, err) in
            
            guard let httpResponse = res as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            if err != nil || data == nil { return }
            
            do {
                self.indexData = try JSONDecoder().decode([StockIndexData].self, from: data!)
                
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet(0...0), with: UITableView.RowAnimation.automatic)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        IPTask.resume()
    }
    
    func getIndexInvestorsData() {
        guard let url:URL = URL(string: "\(SITEURL)/app-data/stock/index-investors") else {
            return
        }
        var request:URLRequest = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = apiHeader
        
        let IPTask = URLSession.shared.dataTask(with: request) { (data, res, err) in
            
            guard let httpResponse = res as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            if err != nil || data == nil { return }
            
            do {
                let indexInvestorsData: StockIndexInvestorsData = try JSONDecoder().decode(StockIndexInvestorsData.self, from: data!)
                
                self.investorsData = indexInvestorsData.investors
                self.indexData = indexInvestorsData.index
                
                
                    
                DispatchQueue.main.async {
                    if self.tableView.numberOfSections > 2 {
                        self.tableView.reloadSections(IndexSet(0...1), with: UITableView.RowAnimation.automatic)
                    }
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        IPTask.resume()
    }
    
    
    func createScheduledTimer() {
        if self.stockDataUpdateScheduledTimer == nil {
            self.stockDataUpdateScheduledTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(stockUpdate), userInfo: nil, repeats: true)
        }
    }
    
    func removeScheduledTimer() {
        if self.stockDataUpdateScheduledTimer != nil {
            self.stockDataUpdateScheduledTimer?.invalidate()
            self.stockDataUpdateScheduledTimer = nil
        }
    }
    
    @objc func stockUpdate() {
        self.getIndexInvestorsData()
    }
    
    
    @objc func newsDataReload() {
        
        guard let url:URL = URL(string: "\(SITEURL)/app-data/stock/newsList") else {
            return
        }
        
        marketIndexViewController?.activityIndicator.startAnimating()
 
        var request:URLRequest = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = apiHeader
        
        let IPTask = URLSession.shared.dataTask(with: request) { (data, res, err) in
            
            guard let httpResponse = res as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            if err != nil || data == nil { return }
            
            do {
                self.newsData = try JSONDecoder().decode([StockNewsData].self, from: data!)
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet(2...2), with: UITableView.RowAnimation.fade)
                    marketIndexViewController?.activityIndicator.stopAnimating()
                    
                }
            } catch let error {
                DispatchQueue.main.async {
                    marketIndexViewController?.activityIndicator.stopAnimating()
                }
                print(error.localizedDescription)
            }
        }
        
        IPTask.resume()
    }
}




struct StockIndexData: Decodable {
    var 종목: String
    var 종목명: String
    var 거래일자: String
    var 종가: String
    var 대비부호: String
    var 등락률: String
    var 전일대비: String
}

struct StockNewsData: Decodable {
    var title: String
    var url: String
    var time: String
}

struct StockInvestorsData: Decodable {
    var 지수: String
    var 개인: String
    var 기관: String
    var 외국인: String
}

struct StockAllData: Decodable {
    var index: [StockIndexData]
    var news: [StockNewsData]?
    var investors: [StockInvestorsData]
}

struct StockIndexInvestorsData: Decodable {
    var index: [StockIndexData]
    var investors: [StockInvestorsData]
}

class StockIndexTableCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var netChange: UILabel!
    @IBOutlet weak var date: UILabel!
}

class StockNewsTableCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    
}

class StockInvestorsTableCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var individualPrice: UILabel!
    @IBOutlet weak var foreignerPrice: UILabel!
    @IBOutlet weak var organizationPrice: UILabel!
}

class StockNewsSectionHeader: UITableViewCell {
    @IBOutlet weak var newsReloadButton: UIButton!
}


//class StockPadIndexTableCell: UITableViewCell {
//    @IBOutlet weak var name: UILabel!
//    @IBOutlet weak var price: UILabel!
//    @IBOutlet weak var netChange: UILabel!
//    @IBOutlet weak var date: UILabel!
//}
