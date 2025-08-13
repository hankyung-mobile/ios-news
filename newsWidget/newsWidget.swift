//
//  newsWidget.swift
//  newsWidget
//
//  Created by hkcom on 2020/09/17.
//  Copyright © 2020 hkcom. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let newsList = getNewsList()
        return SimpleEntry(date:Date(), newsList: newsList)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let newsList = getNewsList()
        let entry = SimpleEntry(date:Date(), newsList: newsList)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        let url:URL = URL(string: "https://www.hankyung.com/app-data/widget/newsList")!
        var request:URLRequest = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Content-Type":"application/json", "authkey":"7a04c8471b5850a07a47537ff309f0726e57ce9e2d9d081663a94de24ecaf6c7"]
        
        
        let IPTask = URLSession.shared.dataTask(with: request) { (data, res, err) in
            do {
                let newsList: [HKNews] = try JSONDecoder().decode([HKNews].self, from: data!)
                let entry = SimpleEntry(date: currentDate, newsList: newsList)
                entries.append(entry)
                
                let timeline = Timeline(entries: entries, policy: .after(refreshDate))
                completion(timeline)

            } catch let error {
                print(error.localizedDescription)
            }
        }
        IPTask.resume()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let newsList: [HKNews]
}

struct newsWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family
        
    var listCount: Int {
        switch family {
        case .systemMedium:
            return 3
        default:
            return 9
        }
    }
    
    var body: some View {
        VStack(content: {
            
            Image("widget_logo")
                .frame(minWidth:0.0, maxWidth: .infinity, alignment: .leading)
                .widgetPaddingLogo()
//                .padding(.init(top: 15.0, leading: 20.0, bottom: 0.0, trailing: 0.0))
            
            Divider()
                .widgetPaddingDivider()
            VStack(alignment: .leading, spacing: 0, content: {
                ForEach(0..<min(listCount, entry.newsList.count), id: \.self) { index in
                    Link(destination: URL(string: "hknews://newsview?url=\(entry.newsList[index].url)")!, label: {
                        Text(entry.newsList[index].title).font(.body).lineLimit(1)
                    })
                    
                    if index + 1 < listCount {
                        Spacer()
                    }
                }
            })
            .widgetPaddingContent()
//            .padding(.horizontal, 20.0).padding(.bottom, 20.0)//.padding(.top, 15.0)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }).widgetBackground(Color.white)
    }
}

@main
struct newsWidget: Widget {
    let kind: String = "newsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            newsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("한국경제 Widget")
        .description("한국경제신문에서 제공하는 뉴스 정보")
        .supportedFamilies([.systemMedium, .systemLarge])
        
    }
}

struct newsWidget_Previews: PreviewProvider {
    static var previews: some View {
        let newsList = getNewsList()
        newsWidgetEntryView(entry: SimpleEntry(date: Date(), newsList: newsList))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

struct HKNews: Decodable {
    var title: String
    var url: String
}

func getNewsList()-> [HKNews] {
    
    let newsList = [
        HKNews(title: "오늘 꼭 봐야 할 뉴스를 제공합니다.", url:"https://www.hankyung.com/")
    ]

    return newsList
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
//                backgroundView
            }
        } else {
            return background(Color.clear)
        }
    }
    
    func widgetPaddingLogo() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return padding(0.0)
        } else {
            return padding(.init(top: 15.0, leading: 20.0, bottom: 0.0, trailing: 0.0))
        }
    }
    
    func widgetPaddingContent() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return padding(0.0)
        } else {
            return padding(.init(top: 0.0, leading: 20.0, bottom: 20.0, trailing: 20.0))
        }
    }
    
    func widgetPaddingDivider() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return padding(0.0)
        } else {
            return padding(.horizontal, 20)
        }
    }

}
