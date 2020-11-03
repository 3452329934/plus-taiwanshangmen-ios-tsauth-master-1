//
//  TSWebEidtor.swift
//  ThinkSNS +
//
//  Created by 小唐 on 22/01/2018.
//  Copyright © 2018 ZhiYiCX. All rights reserved.
//
//  使用WKWebView实现的编辑器

import UIKit
import WebKit

/// WbeView编辑器
class TSWebEidtor: WKWebView {

    // MARK: - Internal Property

    // MARK: - Private Property

    /// 是否格式化html标记
    fileprivate var formatHTML: Bool = false
    /// html相关是否加载，用于加载数据时判断
    fileprivate var resourcesLoaded: Bool = false
    /// 编辑器是否加载，用于直接设置html代码时判断
    fileprivate var editorLoaded: Bool = false
    ///
    fileprivate var internalHTML: String = ""

    // MARK: - Initialize Function
    init(userContentController: (UIViewController & WKScriptMessageHandler)) {
        let wkConfig = WKWebViewConfiguration()
        wkConfig.preferences = WKPreferences()
        wkConfig.preferences.javaScriptCanOpenWindowsAutomatically = true
        wkConfig.mediaPlaybackRequiresUserAction = false
        wkConfig.allowsInlineMediaPlayback = true
        wkConfig.processPool = WKProcessPool()
        wkConfig.userContentController = WKUserContentController()
        wkConfig.userContentController.add(userContentController, name: "MobilePhoneCall")
        super.init(frame: .zero, configuration: wkConfig)
        initialUI()
    }

//    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
//        let wkConfig = WKWebViewConfiguration()
//        wkConfig.preferences = WKPreferences()
//        wkConfig.preferences.javaScriptCanOpenWindowsAutomatically = true
//        wkConfig.mediaPlaybackRequiresUserAction = false
//        wkConfig.allowsInlineMediaPlayback = true
//        wkConfig.processPool = WKProcessPool()
//        wkConfig.userContentController = WKUserContentController()
//        super.init(frame: frame, configuration: wkConfig)
//        wkConfig.userContentController.add(self, name: "MobilePhoneCall")
//        initialUI()
//    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialUI()
    }

    // MARK: - LifeCircle Function

    // MARK: - Private  UI

    // 界面布局
    private func initialUI() -> Void {
        //self.dataDetectorTypes = UIDataDetectorTypeNone(rawValue: 0)
        self.backgroundColor = UIColor.white
        self.scrollView.bounces = false
        self.scrollView.contentInset = UIEdgeInsets.zero
        self.scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        self.scrollView.alwaysBounceHorizontal = false
    }

}


// MARK: - Private  数据加载

extension TSWebEidtor {
    /// 加载数据
    func loadData() -> Void {
        if !self.resourcesLoaded {
            self.loadLocalHtmlData()
        }
        //self.formatHTML = true
    }

    /// 加载本地网页数据
    fileprivate func loadLocalHtmlData() -> Void {
        guard let htmlPath = Bundle.main.path(forResource: "common_editor01", ofType: "html"), let jsPath = Bundle.main.path(forResource: "common_editor01", ofType: "js") else {
            return
        }
        let htmlData: Data = try! Data(contentsOf: URL(fileURLWithPath: htmlPath))
        let jsData: Data = try! Data(contentsOf: URL(fileURLWithPath: jsPath))

        if var htmlString = String(data: htmlData, encoding: String.Encoding.utf8), let jsString = String(data: jsData, encoding: String.Encoding.utf8) {
            if let type = UserDefaults.standard.object(forKey: "webEditorType") as? String {
                if (type == "question") {
                    htmlString = htmlString.replacingOccurrences(of: "输入要说的话，图文结合更精彩哦".localized, with: "详情描述你的问题，有助于受到准确的回答")
                } else if (type == "reply") {
                    htmlString = htmlString.replacingOccurrences(of: "输入要说的话，图文结合更精彩哦".localized, with: "请输入你的回答")
                }
                UserDefaults.standard.removeObject(forKey: "webEditorType")
                UserDefaults.standard.synchronize()
            }
            let html = htmlString.replacingOccurrences(of: "<!--editor-->", with: jsString)
            self.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
            self.resourcesLoaded = true
        }
        //self.loadCustomCss()
    }
    /// 加载自定义CSS文件
    fileprivate func loadCustomCss() -> Void {
        guard let cssPath = Bundle.main.path(forResource: "common_editor", ofType: "css") else {
            return
        }
        let cssData: Data = try! Data(contentsOf: URL(fileURLWithPath: cssPath))
        if let cssString = String(data: cssData, encoding: String.Encoding.utf8) {
            let js = String(format: "webeditor.setCustomCSS(\"%@\");", cssString)
            self.executeJS(js) { (aInfo, aError) in
            }
        }
    }

}

// MARK: - Internal Function

extension TSWebEidtor {
    /// 执行js
    func executeJS(_ js: String, complete: @escaping(_ info: Any?, _ error: Error?) -> Void) {
        TSLogCenter.log.debug("开始执行js \(js)")
        evaluateJavaScript(js) { (info, error) in
            TSLogCenter.log.debug("js \(js) 执行结果:\n\(error.debugDescription)")
            complete(info, error)
        }
    }

    func prepareInsert() -> Void {
        let js = "webeditor.prepareInsert();"
        self.executeJS(js) { (info, error) in
        }
    }
}

// MARK: - Html

extension TSWebEidtor {

    func setHTML(_ html: String) -> Void {
        self.internalHTML = html
        if self.editorLoaded {
            self.updateHTML()
        }
    }

    func updateHTML() -> Void {
        let html = self.internalHTML
        let cleanedHTML = self.removeQuotesFromHTML(html)
        let trigger = String(format: "webeditor.setHTML(\"%@\");", cleanedHTML)
        executeJS(trigger) { (info, error) in
        }
    }

    func getHTML(complete: @escaping(_ aHtml: String?) -> Void) {
        executeJS("webeditor.getHTML();") { (info, error) in
            if let info = info as? String {
                var html = self.removeQuotesFromHTML(info)
                self.tidyHTML(html) { (getHtml) in
                    complete(getHtml)
                }
            } else {
                complete(nil)
            }
        }
    }

    func insertHTML(_ html: String) -> Void {
        let cleanedHTML = self.removeQuotesFromHTML(html)
        let trigger = String(format: "webeditor.insertHTML(\"%@\");", cleanedHTML)
        executeJS(trigger) { (info, error) in
        }
    }
}

// MARK: - setContent

extension TSWebEidtor {
    func setContentWithMarkdown(_ markdown: String) -> Void {
        let js = String(format: "webeditor.setContentWithMarkdown(\"%@\");", markdown)
        executeJS(js) { (info, error) in
        }
    }
    /// markdown加载完成后的图片响应事件添加
    func markdownLoadedImageActionProcess() -> Void {
        let js = String(format: "webeditor.loadedImageActionProcess()")
        executeJS(js) { (info, error) in
        }
    }
    /// markdown加载加载完成后图片markdown字段添加
    func markdownLoadedImageProcess(dicArray: [[String: Int]]) -> Void {
        for dic in dicArray {
            if let index = dic["index"], let fileId = dic["fileId"] {
                let js = String(format: "webeditor.loadedImageProcess(\"%d\", \"%d\");", index, fileId)
                executeJS(js) { (info, error) in
                }
            }
        }
    }
}

// MARK: - 高度

extension TSWebEidtor {
    func setFooterHeight(_ height: CGFloat) -> Void {
        let js = String(format: "webeditor.setFooterHeight(\"%f\");", height)
        executeJS(js) { (info, error) in
        }
    }
    func setContentHeight(_ height: CGFloat) -> Void {
        let js = String(format: "webeditor.contentHeight = %f;", height)
        executeJS(js) { (info, error) in
        }
    }
    func setContentMinHeight(_ height: CGFloat) -> Void {
        let js = String(format: "webeditor.setContentMinHeight(\"%f\")", height)
        executeJS(js) { (info, error) in
        }
    }
}

// MARK: - 光标 聚焦

extension TSWebEidtor {
    func focusContentEditor() -> Void {
        let js = String(format: "webeditor.focusEditor();")
        executeJS(js) { (info, error) in
        }
    }
    func blurContentEditor() -> Void {
        let js = String(format: "webeditor.blurEditor();")
        executeJS(js) { (info, error) in
        }
    }
}

// MARK: - 内容

extension TSWebEidtor {

    func setPlaceholderText(_ placeholder: String) -> Void {
        let js = String(format: "webeditor.setPlaceholder(\"%@\");", placeholder)
        executeJS(js) { (info, error) in
        }
    }

    func getContentMarkdown() {
        let js = String(format: "webeditor.getContentMarkdown();")
        executeJS(js) { (info, error) in
        }
    }

    func getContentText() {
        let trigger = "webeditor.getContentText();"
        executeJS(trigger) { (info, error) in
        }
    }
}

// MARK: - TWRichTextStyle样式

extension TSWebEidtor {

    func setTextStyle(_ textStyle: TSEditorTextStyle, selectedState: Bool) -> Void {
        switch textStyle {
        case .bold:
            self.setBold()
        case .italic:
            self.setItalic()
        case .strikethrough:
            self.setStrikethrough()
        case .h1:
            self.heading1()
        case .h2:
            self.heading2()
        case .h3:
            self.heading3()
        case .h4:
            self.heading4()
        case .hr:
            self.setHR()
        case .undo:
            self.undo()
        case .redo:
            self.redo()
        case .blockquote:
            if selectedState {
                self.removeBlockquote()
            } else {
                self.setBlockquote()
            }
        default:
            break
        }
    }

}
/// TWRichTextStyle下的style支持
extension TSWebEidtor {

    func setBold() -> Void {
        let js = String(format: "webeditor.setBold();")
        executeJS(js) { (info, error) in
        }
    }

    func setItalic() -> Void {
        let js = String(format: "webeditor.setItalic();")
        executeJS(js) { (info, error) in
        }
    }

    func setUnderline() -> Void {
        let js = String(format: "webeditor.setUnderline();")
        executeJS(js) { (info, error) in
        }
    }

    func setStrikethrough() -> Void {
        let js = String(format: "webeditor.setStrikeThrough();")
        executeJS(js) { (info, error) in
        }
    }

    func setHR() -> Void {
        //let js = String(format: "webeditor.setHorizontalRule();")
        //self.executeJS(js)
        self.insertHTML("<div><hr /><br /></div>")
    }

    func setBlockquote() -> Void {
        let js = String(format: "webeditor.setBlockquote();")
        executeJS(js) { (info, error) in
        }
    }

    func removeBlockquote() -> Void {
        let js = String(format: "webeditor.removeBlockquote();")
        executeJS(js) { (info, error) in
        }
    }

    func heading1() -> Void {
        let js = String(format: "webeditor.setHeading('h1');")
        executeJS(js) { (info, error) in
        }
    }
    func heading2() -> Void {
        let js = String(format: "webeditor.setHeading('h2');")
        executeJS(js) { (info, error) in
        }
    }
    func heading3() -> Void {
        let js = String(format: "webeditor.setHeading('h3');")
        executeJS(js) { (info, error) in
        }
    }
    func heading4() -> Void {
        let js = String(format: "webeditor.setHeading('h4');")
        executeJS(js) { (info, error) in
        }
    }
    func heading5() -> Void {
        let js = String(format: "webeditor.setHeading('h5');")
        executeJS(js) { (info, error) in
        }
    }
    func heading6() -> Void {
        let js = String(format: "webeditor.setHeading('h6');")
        executeJS(js) { (info, error) in
        }
    }

    func undo() -> Void {
        let js = String(format: "webeditor.undo();")
        executeJS(js) { (info, error) in
        }
    }
    func redo() -> Void {
        let js = String(format: "webeditor.redo();")
        executeJS(js) { (info, error) in
        }
    }

}

// MARK: - Other Style

extension TSWebEidtor {
    func removeFormat() -> Void {
        let js = String(format: "webeditor.removeFormating();")
        executeJS(js) { (info, error) in
        }
    }

    func alignLeft() -> Void {
        let js = String(format: "webeditor.setJustifyLeft();")
        executeJS(js) { (info, error) in
        }
    }
    func alignCenter() -> Void {
        let js = String(format: "webeditor.setJustifyCenter();")
        executeJS(js) { (info, error) in
        }
    }
    func alignRight() -> Void {
        let js = String(format: "webeditor.setJustifyRight();")
        executeJS(js) { (info, error) in
        }
    }
    func alignFull() -> Void {
        let js = String(format: "webeditor.setJustifyFull();")
        executeJS(js) { (info, error) in
        }
    }

    func setUnorderedList() -> Void {
        let js = String(format: "webeditor.setUnorderedList();")
        executeJS(js) { (info, error) in
        }
    }
    func setOrderedList() -> Void {
        let js = String(format: "webeditor.setOrderedList();")
        executeJS(js) { (info, error) in
        }
    }

    func setSubscript() -> Void {
        let js = String(format: "webeditor.setSubscript();")
        executeJS(js) { (info, error) in
        }
    }
    func setSuperscript() -> Void {
        let js = String(format: "webeditor.setSuperscript();")
        executeJS(js) { (info, error) in
        }
    }

    func setIndent() -> Void {
        let js = String(format: "webeditor.setIndent();")
        executeJS(js) { (info, error) in
        }
    }
    func setOutdent() -> Void {
        let js = String(format: "webeditor.setOutdent();")
        executeJS(js) { (info, error) in
        }
    }

    func paragraph() -> Void {
        let js = String(format: "webeditor.setParagraph();")
        executeJS(js) { (info, error) in
        }
    }

}

// MARK: - 链接

extension TSWebEidtor {
    /// 插入链接
    func insertLink(url: String, title: String) -> Void {
//        self.executeJS("webeditor.prepareInsert();")
        // 注意：上面注释部分需要再键盘关闭之前使用，否则插入失败。同理，插入图片、插入html代码都一样。
        // url校验，scheme + 服务器，不符合该格式则添加"zhiyi"格式的scheme。
        // js里插入链接时校验 "[\\s\\S]+:[\\s\\S]+"
        let js = String(format: "webeditor.insertLink(\"%@\", \"%@\");", url, title)
        executeJS(js) { (info, error) in
        }
    }

    /// 修改链接
    func updateLink(url: String, title: String) -> Void {
//        self.executeJS("webeditor.prepareInsert();")
        let js = String(format: "webeditor.updateLink(\"%@\", \"%@\");", url, title)
        executeJS(js) { (info, error) in
        }
    }

    /// 移除链接
    func removeLink() -> Void {
        let js = "webeditor.unlink();"
        executeJS(js) { (info, error) in
        }
    }

    /// quickLink
    func quickLink() -> Void {
        let js = "webeditor.quickLink();"
        executeJS(js) { (info, error) in
        }
    }
}

// MARK: - 图片

extension TSWebEidtor {
    func insertImage(url: String, alt: String) -> Void {
        self.executeJS("webeditor.prepareInsert();") { (aInfo, aError) in
        }
        let trigger = String(format: "webeditor.insertImage(\"%@\", \"%@\");", url, alt)
        executeJS(trigger) { (info, error) in
        }
    }

    func updateImage(url: String, alt: String) -> Void {
        executeJS("webeditor.prepareInsert();") { (info, error) in
        }
        let trigger = String(format: "webeditor.updateImage(\"%@\", \"%@\");", url, alt)
        executeJS(trigger) { (info, error) in
        }
    }

    func insertImage(url: String, imageIndex: Int, alt: String, width: CGFloat, height: CGFloat) -> Void {
        executeJS("webeditor.prepareInsert();") { (info, error) in
        }
        let trigger = String(format: "webeditor.insertImageUrl(\"%@\", \"%d\", \"%@\", \"%f\", \"%f\");", url, imageIndex, alt, width, height)
        executeJS(trigger) { (info, error) in
        }
    }

    func insertImage(_ image: UIImage, imageIndex: Int, alt: String, width: CGFloat, height: CGFloat) -> Void {
        // 若需查看html源码，base64太长，不便于查看html结构
        //let base64String = "base64ForJpgImage"
        let base64String = self.base64ForJpgImage(image)
        self.insertImage(base64String: base64String, imageIndex: imageIndex, alt: alt, width: width, height: height)
    }
    func insertImage(base64String: String, imageIndex: Int, alt: String, width: CGFloat, height: CGFloat) -> Void {
        executeJS("webeditor.prepareInsert();") { (info, error) in
            let trigger = String(format: "webeditor.insertImageBase64String(\"%@\", \"%d\", \"%@\", \"%f\", \"%f\");", base64String, imageIndex, alt, width, height)
            self.executeJS(trigger) { (aInfo, aError) in
            }
        }

    }

    func removeImage(imageIndex: Int) -> Void {
        let trigger = String(format: "webeditor.removeImage(\"%d\")", imageIndex)
        self.executeJS(trigger) { (aInfo, aError) in
        }
    }

    /// 上传图片成功
    func uploadImageSuccess(imageIndex: Int, fileId: Int) -> Void {
        let trigger = String(format: "webeditor.uploadImageSuccess(\"%d\", \"%d\")", imageIndex, fileId)
        self.executeJS(trigger) { (aInfo, aError) in
        }
    }
    /// 上传图片失败
    func uploadImageFailure(imageIndex: Int) -> Void {
        /// html界面展示处理
        let trigger = String(format: "webeditor.uploadImageFailure(\"%d\")", imageIndex)
        self.executeJS(trigger) { (aInfo, aError) in
        }
    }

    func base64SourceForJpegImage(_ image: UIImage) -> String {
        guard let imgData = image.jpegData(compressionQuality: 1.0) else {
            return ""
        }
        let imageSource = String(format: "data:image/jpg;base64,%@", imgData.base64EncodedString())
        return imageSource
    }
    func base64ForJpgImage(_ image: UIImage) -> String {
        guard let imgData = image.jpegData(compressionQuality: 1.0) else {
            return ""
        }
        return imgData.base64EncodedString()
    }

    /// 根据图片索引id判断该图片是否存在
    func isExistImage(imageIndex: Int, complete: @escaping(_ exist: Bool) -> Bool) {
        let trigger = String(format: "webeditor.isExistImage(\"%d\");", imageIndex)
        var isExistFlag: Bool = false
        self.executeJS(trigger) { (aInfo, aError) in
            if let info = aInfo as? String, info == "1" {
                complete(true)
            } else {
                complete(false)
            }
        }
    }
}

// MARK: - Utilities
extension TSWebEidtor {
    fileprivate func removeQuotesFromHTML(_ html: String) -> String {
        var result: String = html.replacingOccurrences(of: "\"", with: "\\\"")
        result = result.replacingOccurrences(of: "", with: "")
        result = result.replacingOccurrences(of: "“", with: "&quot;")
        result = result.replacingOccurrences(of: "”", with: "&quot;")
        result = result.replacingOccurrences(of: "\r", with: "\\r")
        result = result.replacingOccurrences(of: "\n", with: "\\n")
        return result
    }
    fileprivate func tidyHTML(_ html: String, complete: @escaping(_ html: String?) -> Void) {
        var result: String = html.replacingOccurrences(of: "<br>", with: "<br />")
        result = result.replacingOccurrences(of: "<hr>", with: "<hr />")
        if self.formatHTML {
            let js = String(format: "style_html(\"%@\");", html)
            executeJS(js) { (info, error) in
                if let info = info as? String {
                    complete(info)
                }
            }
        }
        complete(nil)
    }
}

extension TSWebEidtor {

    func decodingURLFormat(url: String) -> String {
        var result: String = url.replacingOccurrences(of: "+", with: " ")
        result = result.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        return result
    }

}
