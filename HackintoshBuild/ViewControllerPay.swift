//
//  ViewControllerPay.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2020/2/17.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa

class ViewControllerPay: NSViewController {

    @IBOutlet weak var alipayImageView: NSImageView!
    @IBOutlet weak var wechatpayImageView: NSImageView!
    
    let alipay = Bundle.main.path(forResource: "alipay", ofType: "jpg")
    let wechatpay = Bundle.main.path(forResource: "wechatpay", ofType: "jpg")    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        image(alipay!, alipayImageView)
        image(wechatpay!, wechatpayImageView)
    }
    
    func image(_ url: String,_ imageView: NSImageView) {
        let url = NSURL(fileURLWithPath: url)
        let image = NSImage(contentsOf: url as URL)!
        imageView.image = image
    }
    
}
