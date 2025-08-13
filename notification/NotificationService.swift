//
//  NotificationService.swift
//  notification
//
//  Created by InTae Gim on 6/18/24.
//  Copyright © 2024 hkcom. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
           
            guard request.content.userInfo["fcm_options"] != nil else {
                contentHandler(bestAttemptContent)
                return
            }
            
            let imageData = request.content.userInfo["fcm_options"] as! [String : Any]
            
            guard let urlImageString = imageData["image"] as? String else {
                contentHandler(bestAttemptContent)
                return
            }
            
            if let imageUrl = URL(string: "\(urlImageString)") {
                guard let imageData = try? Data(contentsOf: imageUrl) else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                // url을 임시로 저장한 후 저장된 파일 경로를 가져온다.
                guard let attachment = UNNotificationAttachment.saveImageToDisk(identifier: "pushimage.jpg", data: imageData, options: nil) else {
                    contentHandler(bestAttemptContent)
                    return
                }

                bestAttemptContent.attachments = [ attachment ]
            }
            
            contentHandler(bestAttemptContent)
            
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

extension UNNotificationAttachment {
    static func saveImageToDisk(identifier: String, data: Data, options: [AnyHashable : Any]? = nil) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        let folderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)!

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            let fileURL = folderURL.appendingPathExtension(identifier)
            try data.write(to: fileURL)
            let attachment = try UNNotificationAttachment(identifier: identifier, url: fileURL, options: options)
            return attachment
        } catch {
            print("saveImageToDisk error - \(error)")
        }
        return nil
    }
}
