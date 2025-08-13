//
//  BlockchainViewController.swift
//  newsApp
//
//  Created by hkcom on 2020/08/21.
//  Copyright © 2020 hkcom. All rights reserved.
//

import UIKit

class BlockchainTableViewController: UITableViewController {
    var coinDataUpdateScheduledTimer: Timer? = nil
    var coinData: [BlockchainCoinData] = []
//    var coinData: [BlockchainCoinData] = [] {
//        didSet {
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
//        }
//    }
    
    var newsData: [BlockchainNewsData] = []
    var bannerData: BlockchainBannerData? = nil
    
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
        // #warning Incomplete implementation, return the number of sections
        if coinData.count == 0 {
            return 0
        }
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return coinData.count
        case 1:
            return 1
        case 2:
            return newsData.count
        default:
            return 0
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        switch section {
        case 0:
            
//            let cell = tableView.dequeueReusableCell(withIdentifier: "coinHeader") as! BlockchainCoinSectionHeader
//            
//            if self.coinData.count > 0 {
//                cell.date.text = self.coinData[0].거래일
//            }
//            
//            return cell.contentView
            return nil
            
        case 1:
            return tableView.dequeueReusableCell(withIdentifier: "bannerHeader")?.contentView
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "newsHeader") as! BlockchainNewsSectionHeader
            
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
        case 1:
            return 40
        default:
            return 72
        }
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            var cellName: String = "coinCell"
            
            if UI_USER_INTERFACE_IDIOM() == .pad {
                cellName = "padCoinCell"
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath) as! BlockchainCoinTableCell
            
            let data: BlockchainCoinData = self.coinData[indexPath.row]
            
            cell.title.text = data.종목
            cell.date.text = data.거래일
            cell.price.text = data.현재가
            cell.netChange.text = "\(data.대비부호)\(data.등락률)%"
            
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
    
            let cell = tableView.dequeueReusableCell(withIdentifier: "bannerCell", for: indexPath) as! BlockchainBannerTableCell
            
            guard let banner = self.bannerData else {
                return cell
            }
            
            
            let src: URL! = URL(string: banner.image)

            do {
                let imgData = try Data(contentsOf: src)
                let img: UIImage = UIImage(data: imgData)!
                cell.bannerImg.image = img
            } catch { }
            
            cell.backgroundColor = UIColor(rgb: Int(banner.backgroundColor) ?? 0xFFFFFF)

            return cell
        }
        else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! BlockchainNewsTableCell
            
//            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
            
            let data: BlockchainNewsData = self.newsData[indexPath.row]
            
            cell.title.text = data.title
            
            return cell
        }
        return UITableViewCell()
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.section > 0 else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        guard indexPath.section == 2 else {
            
            if bannerData == nil {
                
                let appStoreUrl: URL = URL(string: "https://bloomingbit.page.link/e69e")!
                UIApplication.shared.open(appStoreUrl, options: [:])

//                let appURL: URL = URL(string: "hkplus://plus")!
//
//                if UIApplication.shared.canOpenURL(appURL) {
//                    UIApplication.shared.open(appURL, options: [:])
//                }else {
//                    let appStoreUrl: URL = URL(string: "https://apps.apple.com/kr/app/id1518507602?mt=8")!
//                    UIApplication.shared.open(appStoreUrl, options: [:])
//                }
            } else {
                if let bannerUrl: URL = URL(string: self.bannerData!.link) {
                    UIApplication.shared.open(bannerUrl, options: [:])
                }
            }
            
            
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
        avc.viewTitleText = "가상화폐 뉴스"
    }
    
    
}

extension BlockchainTableViewController {
    
    func getAllData() {
        guard let url:URL = URL(string: "\(SITEURL)/app-data/blockchain/all") else {
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
                let allData: BlockchainAllData = try JSONDecoder().decode(BlockchainAllData.self, from: data!)
                
                if(allData.banner != nil){
                    self.bannerData = allData.banner
                }
                self.newsData = allData.news ?? []
                self.coinData = allData.coin
                
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
    
    func getCoinData() {
        guard let url:URL = URL(string: "\(SITEURL)/app-data/blockchain/coinList") else {
            return
        }
        var request:URLRequest = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = apiHeader
        
        let IPTask = URLSession.shared.dataTask(with: request) { (data, res, err) in
            
            guard let httpResponse = res as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            if err != nil || data == nil { return }
            
            do {
                self.coinData = try JSONDecoder().decode([BlockchainCoinData].self, from: data!)
                
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet(0...0), with: UITableView.RowAnimation.automatic)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        IPTask.resume()
    }
    
    func createScheduledTimer() {
        if self.coinDataUpdateScheduledTimer == nil {
            self.coinDataUpdateScheduledTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(coinUpdate), userInfo: nil, repeats: true)
        }
    }
    
    func removeScheduledTimer() {
        if self.coinDataUpdateScheduledTimer != nil {
            self.coinDataUpdateScheduledTimer?.invalidate()
            self.coinDataUpdateScheduledTimer = nil
        }
    }
    
    @objc func coinUpdate() {
        self.getCoinData()
    }
    
    @objc func newsDataReload() {
        
        guard let url:URL = URL(string: "\(SITEURL)/app-data/blockchain/newsList") else {
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
                self.newsData = try JSONDecoder().decode([BlockchainNewsData].self, from: data!)
                
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet(2...2), with: UITableView.RowAnimation.automatic)
                    
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


struct BlockchainCoinData: Decodable {
    var 종목: String
    var 코드: String
    var 현재가: String
    var 전일대비: String
    var 등락률: String
    var 대비부호: String
    var 거래일: String
}

struct BlockchainNewsData: Decodable {
    var title: String
    var url: String
    var time: String
}

struct BlockchainBannerData: Decodable {
    var link: String
    var image: String
    var backgroundColor: String
}

struct BlockchainAllData: Decodable {
    var coin: [BlockchainCoinData]
    var news: [BlockchainNewsData]?
    var banner: BlockchainBannerData?
}


class BlockchainCoinTableCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var netChange: UILabel!
    @IBOutlet weak var date: UILabel!
}

class BlockchainNewsTableCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}

class BlockchainBannerTableCell: UITableViewCell {
    @IBOutlet weak var bannerImg: UIImageView!
}

class BlockchainNewsSectionHeader: UITableViewCell {
    @IBOutlet weak var newsReloadButton: UIButton!
}

class BlockchainCoinSectionHeader: UITableViewCell {
    @IBOutlet weak var date: UILabel!
}
