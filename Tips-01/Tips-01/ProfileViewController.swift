//
//  ViewController.swift
//  Tips-01
//
//  Created by lucas on 16/8/24.
//  Copyright © 2016年 三只小猪. All rights reserved.
//

import UIKit
import MessageUI
import WebKit

struct URLSchema {
    static let sms = "sms://"
    static let tel = "tel://"
    static let telprompt = "telprompt://"
    static let mailto = "mailto://"
}

enum CallMode {
    case application
    case webView
}

enum MessageMode {
    case application
    case message
}

class ProfileViewController: UITableViewController {
    
    lazy var webView: UIWebView = {
        let result = UIWebView(frame: CGRectZero)
        return result
    }()
    
    var callMode = CallMode.application
    
    var messageMode = MessageMode.application
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(webView)
    }
    
    deinit {
        webView.removeFromSuperview()
    }
    
    
    @IBAction func takeCallPhoneMode(sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex;
        if index == 0 {
            self.callMode = .application
        } else {
            self.callMode = .webView
        }
    }
    
    @IBAction func takeSendMailAndSMSMode(sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex;
        if index == 0 {
            self.messageMode = .application
        } else {
            self.messageMode = .message
        }
    }
}

extension ProfileViewController {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(PhoneViewCell.identifier, forIndexPath: indexPath) as! PhoneViewCell
            cell.delegate = self
            return cell
        }
        return tableView.dequeueReusableCellWithIdentifier("EmailViewCell", forIndexPath: indexPath)
    }
}

extension ProfileViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let phoneCell = cell as? PhoneViewCell, phone = phoneCell.detailLabel.text {
            if self.callMode == .application {
                self.callPhoneByApplication(withPhone: phone)
            } else {
                self.callPhoneByWebView(withPhone: phone)
            }
            return
        }
        
        guard let email = cell?.detailTextLabel?.text else {
            return
        }
        if self.messageMode == .application {
            self.composeEmailByApplication(withEmail: email)
        } else {
            self.composeEmailByMessage(withEmail: email)
        }
    }
}

extension ProfileViewController: PhoneViewCellDelegate {
    
    func phoneViewCell(phoneViewCell: PhoneViewCell, didClickSendMessageButton sender: UIButton) {
        guard let phone = phoneViewCell.detailLabel.text else {
            return
        }
        if self.messageMode == .application {
            self.sendSMSByApplication(withPhone: phone)
        } else {
            self.sendSMSByMessage(withPhone: phone)
        }
    }
}

extension ProfileViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true) { 
            switch result {
            case MFMailComposeResultCancelled:
                self.alert("邮件发送取消.")
                break
            case MFMailComposeResultSent:
                self.alert("邮件发送成功.")
                break
            case MFMailComposeResultFailed:
                self.alert("邮件发送失败.")
                break
            case MFMailComposeResultSaved:
                self.alert("邮件已保存草稿")
                break
            default:
                break
            }
        }
    }
}

extension ProfileViewController: MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true) { 
            switch result {
            case MessageComposeResultCancelled:
                self.alert("短信发送取消.")
                break
            case MessageComposeResultFailed:
                self.alert("短信发送失败.")
                break
            case MessageComposeResultSent:
                self.alert("消息发送成功.")
                break
            default:
                break
            }
        }
    }
}

extension ProfileViewController {
    
    /**
     打电话
     
     - parameter phone: 电话号码
     */
    private func callPhoneByWebView(withPhone phone: String) {
        webView.loadRequest(NSURLRequest(URL: NSURL(string: URLSchema.tel + phone)!))
    }
 
    private func callPhoneByApplication(withPhone phone: String) {
        openApp(URLSchema.tel + phone)
    }
    
    private func callPhone(phone: String) {
        openApp(URLSchema.telprompt + phone)
    }
    
    /**
     发邮件
     
     - parameter email: 邮箱地址
     */
    private func composeEmailByMessage(withEmail email: String) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients([email])
        self.presentViewController(mailComposeViewController, animated: true, completion: nil)
    }
    
    private func composeEmailByApplication(withEmail email: String) {
        openApp(URLSchema.mailto + email)
    }
    
    /**
     发短信
     
     - parameter phone: 电话号码。
     */
    private func sendSMSByMessage(withPhone phone: String) {
        if !MFMessageComposeViewController.canSendText() {
            return
        }
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self
        messageComposeViewController.recipients = [phone]
        self.presentViewController(messageComposeViewController, animated: true, completion: nil)
    }
    
    private func sendSMSByApplication(withPhone phone: String) {
        openApp(URLSchema.sms + phone)
    }
    
    private func alert(message: String) {
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "好的", style: .Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func openApp(URLSchema: String) {
        guard let url = NSURL(string: URLSchema) else {
            return
        }
        
        if UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}
