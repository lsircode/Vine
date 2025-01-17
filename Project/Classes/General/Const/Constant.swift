//
//  Constant.swift
//  LawChatForLawyer
//
//  Created by Juice on 2017/7/7.
//  Copyright © 2017年 就问律师. All rights reserved.
//

import Foundation
import UIKit

let User_Center = UserCenter.sharedInstance()

/// 获取沙盒Document路径
let kDocumentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
/// 获取沙盒Cache路径
let kCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
/// 获取沙盒temp路径
let kTempPath = NSTemporaryDirectory()

/// 颜色
func kRGBAColor(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> UIColor {
    return UIColor(red: r, green: g, blue: b, alpha: a)
}

func kRGBColor(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
    return UIColor(red: r, green: g, blue: b, alpha: 1.0)
}

func kHexColor(_ HexString: String) -> UIColor {
    return UIColor(hexString: HexString)!
}

let S_APPColor_Green = UIColor(hexString: "1AC095")
let S_APPColor_BackgroudView = UIColor(hexString: "41508E")
let S_APPColor_Blue = UIColor(hexString: "3682ff")
let S_APPColor_Red = UIColor(hexString: "#E6484E")
let S_APPColor_Line = UIColor(hexString: "e6e6e6")

let kColor_000000 = kHexColor("000000")
let kColor_111111 = kHexColor("111111")
let kColor_222222 = kHexColor("222222")
let kColor_333333 = kHexColor("333333")
let kColor_444444 = kHexColor("444444")
let kColor_555555 = kHexColor("555555")
let kColor_666666 = kHexColor("666666")
let kColor_777777 = kHexColor("777777")
let kColor_888888 = kHexColor("888888")
let kColor_999999 = kHexColor("999999")
let kColor_aaaaaa = kHexColor("aaaaaa")
let kColor_bbbbbb = kHexColor("bbbbbb")
let kColor_cccccc = kHexColor("cccccc")
let kColor_dddddd = kHexColor("dddddd")
let kColor_eeeeee = kHexColor("eeeeee")
let kColor_ffffff = kHexColor("ffffff")
/// 大红
let kColor_ff0000 = kHexColor("ff0000")
/// 大黄
let kColor_00ff00 = kHexColor("00ff00")
/// 大蓝
let kColor_0000ff = kHexColor("0000ff")

/// 开发的时候打印，但是发布的时候不打印,使用方法，输入print(message: "输入")
func print<T>(message: T, fileName: String = #file, methodName _: String = #function, lineNumber: Int = #line) {
    #if DEBUG
        // 获取当前时间
        let now = Date()
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        // 要把路径最后的字符串截取出来
        let lastName = ((fileName as NSString).pathComponents.last!)
        print("\(dformatter.string(from: now)) [\(lastName)][第\(lineNumber)行] \n\t\t \(message)")
    #endif
}

/// UserDefaults 操作
let kUserDefaults = UserDefaults.standard
func kUserDefaultsRead(_ KeyStr: String) -> String {
    return kUserDefaults.string(forKey: KeyStr)!
}

func kUserDefaultsWrite(_ obj: Any, _ KeyStr: String) {
    kUserDefaults.set(obj, forKey: KeyStr)
}

func kUserValue(_ A: String) -> Any? {
    return kUserDefaults.value(forKey: A)
}

/// 获取屏幕大小
let kUIScreenSize = UIScreen.main.responds(to: #selector(getter: UIScreen.nativeBounds)) ? CGSize(width: UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale, height: UIScreen.main.nativeBounds.size.height / UIScreen.main.nativeScale) : UIScreen.main.bounds.size
let kUIScreenWidth = kUIScreenSize.width
let kUIScreenHeight = kUIScreenSize.height
let kUIScreenBounds = UIScreen.main.bounds

/// 底部的安全距离
func bottomSafeAreaHeight() -> CGFloat {
    if #available(iOS 11.0, *) {
        return (UIApplication.shared.windows.first?.safeAreaInsets.bottom)!
    } else {
        return 0.0
    }
}

/// 顶部的安全距离
let topSafeAreaHeight = (bottomSafeAreaHeight() == 0 ? 0 : 24)
/// 状态栏高度
let statusBarHeight = UIApplication.shared.statusBarFrame.height
/// 导航栏高度
let navigationWithStatusBarHeight = (CGFloat)(bottomSafeAreaHeight() == 0 ? 64.0 : 88.0)
/// tabbar高度默认高度49     （iPhoneX 83）
let tabBarHeight = (bottomSafeAreaHeight() + 49)

/// APP版本号
let kAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
/// 当前系统版本号
let kVersion = (UIDevice.current.systemVersion as NSString).floatValue
/// 检测用户版本号
let kiOS12 = (kVersion >= 12.0)
let kiOS11 = (kVersion >= 11.0 && kVersion < 12.0)
let kiOS10 = (kVersion >= 10.0 && kVersion < 11.0)
let kiOS9 = (kVersion >= 9.0 && kVersion < 10.0)
let kiOS8 = (kVersion >= 8.0 && kVersion < 9.0)
let kiOS12Later = (kVersion >= 12.0)
let kiOS11Later = (kVersion >= 11.0)
let kiOS10Later = (kVersion >= 10.0)
let kiOS9Later = (kVersion >= 9.0)
let kiOS8Later = (kVersion >= 8.0)

/// 获取当前语言
let kAppCurrentLanguage = Locale.preferredLanguages[0]
/// 判断是否为iPhone
let kDeviceIsiPhone = (UI_USER_INTERFACE_IDIOM() == .phone)
/// 判断是否为iPad
let kDeviceIsiPad = (UI_USER_INTERFACE_IDIOM() == .pad)

/// 判断 iPhone 的屏幕尺寸
let kSCREEN_MAX_LENGTH = max(kUIScreenWidth, kUIScreenHeight)
let kSCREEN_MIN_LENGTH = min(kUIScreenWidth, kUIScreenHeight)

/// 适配 350 375 414       568 667 736
func kAutoLayoutWidth(_ width: CGFloat) -> CGFloat {
    return width * kUIScreenWidth / 375
}

func kAutoLayoutHeigth(_ height: CGFloat) -> CGFloat {
    return height * kUIScreenHeight / 667
}

/// 机型判断
let kUI_IPHONE = (UIDevice.current.userInterfaceIdiom == .phone)
let kUI_IPHONE5 = (kUI_IPHONE && kSCREEN_MAX_LENGTH == 568.0)
let kUI_IPHONE6 = (kUI_IPHONE && kSCREEN_MAX_LENGTH == 667.0)
let kUI_IPHONEPLUS = (kUI_IPHONE && kSCREEN_MAX_LENGTH == 736.0)
let kUI_IPHONEX = (kUI_IPHONE && kSCREEN_MAX_LENGTH > 780.0)

/// 注册通知
func kNOTIFY_ADD(observer: Any, selector: Selector, name: String) {
    return NotificationCenter.default.addObserver(observer, selector: selector, name: Notification.Name(rawValue: name), object: nil)
}

/// 发送通知
func kNOTIFY_POST(name: String, object: Any) {
    return NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: object)
}

/// 移除通知
func kNOTIFY_REMOVE(observer: Any, name: String) {
    return NotificationCenter.default.removeObserver(observer, name: Notification.Name(rawValue: name), object: nil)
}

/// 代码缩写
let kApplication = UIApplication.shared
let kAPPKeyWindow = kApplication.keyWindow
let kAppDelegate = kApplication.delegate
let kAppNotificationCenter = NotificationCenter.default
let kAppRootViewController = kAppDelegate?.window??.rootViewController

/// 字体 字号
func kFontSize(_ a: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: a)
}

func kFontBoldSize(_ a: CGFloat) -> UIFont {
    return UIFont.boldSystemFont(ofSize: a)
}

func kFontForIPhone5or6Size(_ a: CGFloat, _ b: CGFloat) -> UIFont {
    return kUI_IPHONE5 ? kFontSize(a) : kFontSize(b)
}

