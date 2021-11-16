//
//  ViewController.swift
//  ParseXLSX
//
//  Created by 30dayslyh on 2021/1/11.
//

import UIKit
import CoreXLSX

class ViewController: UIViewController {

    let android_file_namesMapping: [String: String] =
        ["中文": "values-zh",
         "中文繁体": "values-zh-rTW",
         "英文": "values-en-rUS",
         "日语": "values-ja-rJP",
         "韩语": "values-ko-rKR",
         "法语": "values-fr-rFR",
         "德语": "values-de-rDE",
         "俄语": "values-ru",
         "乌克兰语": "values-uk-rUA",
         "意大利": "values-it-rIT",
         "西班牙": "values-es-rES",
         "土耳其": "values-tr",
         "葡萄牙": "values-pt-rPT",
         "葡萄牙语": "values-pt-rPT",
         "波兰": "values-pl-rPL",
         "印尼": "values-in-rID",
         "泰语": "values-th-rTH",
         "希伯来": "values-iw-rIL",
         "阿拉伯": "values-ar-rEG",
         "越南": "values-vi-rVN",
         "缅甸": "values-af",
         "希腊": "values-el-rGR",
         "印第": "values-hi-rIN", "印地": "values-hi-rIN"]
    //let ios_file_namesMapping: [String: String] = [:]
    var xmlParser: XMLParser!
    var characters: [String] = []
    var keys: [String] = []
    var values: [String] = []
    var indexes: [Int] = []
    var tempString: String!
    
    //excel path
    let filePath = "/Users/macbook/Desktop/副本补充字段22国语言.xlsx"
    let at_filePath = "/Users/macbook/Desktop/手环翻译(3)(1)_Rus_tkm(2)(1).xlsx"
    let gufeng_filePath = "/Users/macbook/Desktop/Aiwear22国语言(2)(1).xlsx"
    let mosheng_filePath = "/Users/macbook/Desktop/魔声翻译字段(2).xlsx"
    let buchong_filePath = "/Users/macbook/Desktop/补充词0803.xlsx"
    let at_buchong_filePath = "/Users/macbook/Desktop/at补充翻译词.xlsx"

    let black_list = [" ", /*":\\\"", "\\\"", "\"", "\\"*/]
    
    var android_supplementWord_keys: [String] = ["language"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let path = Bundle.main.path(forResource: "strings(8).xml", ofType: nil) else { return }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return }
        xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        if !xmlParser.parse() {
            guard let err = xmlParser.parserError else { return }
            print(err)
        }
    }
    
    @IBAction func generateIOS(_ sender: Any) {
        #warning("记得检查文件路径")
        try? parse(xlsxPath: at_buchong_filePath)
    }
    
    @IBAction func generateAndroid(_ sender: Any) {
        #warning("记得修改 supplement 和文件路径")
        try? parseAnd(xlsxPath: mosheng_filePath, supplement: false)
    }
    
    func parseAnd(xlsxPath: String, supplement: Bool) throws {
        guard let file = XLSXFile(filepath: xlsxPath) else {
            fatalError("XLSX file at \(xlsxPath) is corrupted or does not exist")
        }
        for wbk in try file.parseWorkbooks() {
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                if let worksheetName = name {
                    print("This worksheet has a name: \(worksheetName)")
                }
                let worksheet = try file.parseWorksheet(at: path)
                var columnReferenceList: [ColumnReference] = []
                for row in worksheet.data?.rows ?? [] {
                    for c in row.cells {
                        if !columnReferenceList.contains(c.reference.column) {
                            columnReferenceList.append(c.reference.column)
                        }
                    }
                }
                var columns: [[String]] = []
                if let sharedString = try file.parseSharedStrings() {
                    for column in columnReferenceList {
                        let columnCStrings: [String] = worksheet.cells(atColumns: [column])
                            .compactMap { cell in
                                let str = cell.stringValue(sharedString) ?? cell.richStringValue(sharedString).map{$0.text ?? ""}.joined(separator: "")
                                return str
                        }
                        columns.append(columnCStrings)
                    }
                }
                let basePath = "/Users/macbook/Desktop/localizedTxt-and"
                let firstColumn = columns.first!
                if supplement {
                    for strs in columns {
                        if strs.first == "" {
                            continue
                        }
                        let xmlName = android_file_namesMapping[strs.first!]
                        let tempPath = basePath+"/"+xmlName!+".xml"
                        var text: String = ""
                        for (idx, key) in android_supplementWord_keys.enumerated() {
                            var result = strs[idx]
                            if result.hasPrefix(" ") {
                                result.removeFirst()
                            }
                            if result.hasSuffix(" ") {
                                result.removeLast()
                            }
                            text.append("\t<string name=\"\(key)\">\(result)</string>\n")
                        }
                        try text.write(toFile: tempPath, atomically: true, encoding: .utf8)
                        Thread.sleep(forTimeInterval: 1)
                    }
                } else {
                    for str in values {
                        if let idx = firstColumn.firstIndex(of: str) {
                            indexes.append(idx)
                        } else {
                            indexes.append(-1)
                        }
                    }
                    for strs in columns {
                        if strs.first == "" { break }
                        let xmlName = android_file_namesMapping[strs.first!]
                        let tempPath = basePath+"/"+xmlName!+".xml"
                        var text: String = ""
                        text.append("<resources>\n")
                        for (idx, key) in keys.enumerated() {
                            var tmpKey = key
                            let targetIndex = indexes[idx]
                            if targetIndex == -1 {
//                                text.append("\t<string name=\"\(key)\">\(key)</string>\n")
                            } else {
                                var result = strs[targetIndex]
                                if result.hasPrefix(" ") {
                                    result.removeFirst()
                                }
                                if result.hasSuffix(" ") {
                                    result.removeLast()
                                }
                                if tmpKey.contains("*") {
                                    tmpKey = tmpKey.replacingOccurrences(of: "*", with: "%s")
                                }
                                if result.contains("*") {
                                    result = result.replacingOccurrences(of: "*", with: "%s")
                                }
                                text.append("\t<string name=\"\(tmpKey)\">\(result)</string>\n")
                            }
                        }
                        text.append("</resources>")
                        try text.write(toFile: tempPath, atomically: true, encoding: .utf8)
                        Thread.sleep(forTimeInterval: 1)
                    }
                    print("finish")
                }
            }
        }
    }
    
    func parse(xlsxPath: String) throws {
        guard let file = XLSXFile(filepath: xlsxPath) else {
            fatalError("XLSX file at \(xlsxPath) is corrupted or does not exist")
        }
        for wbk in try file.parseWorkbooks() {
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                if let worksheetName = name {
                    print("This worksheet has a name: \(worksheetName)")
                }
                let worksheet = try file.parseWorksheet(at: path)
                var columnReferenceList: [ColumnReference] = []
                for row in worksheet.data?.rows ?? [] {
                    for c in row.cells {
                        if !columnReferenceList.contains(c.reference.column) {
                            columnReferenceList.append(c.reference.column)
                        }
                    }
                }
                var columns: [[String]] = []
                if let sharedString = try file.parseSharedStrings() {
                    for column in columnReferenceList {
                        let columnCStrings: [String] = worksheet.cells(atColumns: [column])
                            .compactMap { cell in
                                cell.stringValue(sharedString) ?? cell.richStringValue(sharedString).map{$0.text ?? ""}.joined(separator: "")
                        }
                        columns.append(columnCStrings)
                    }
                }
                let first = columns.first!
                let basePath = "/Users/macbook/Desktop/localizedTxt"
                for strs in columns {
                    let tempPath = basePath+"/"+strs.first!+".txt"
                    var text: String = ""
                    for (idx, str) in strs.enumerated() {
                        var result = str
                        var tmpKey = first[idx]
                        for blackItem in black_list {
                            if result.hasPrefix(blackItem) {
                                if let range = result.range(of: blackItem) {
                                    result.removeSubrange(range)
                                }
                            }
                            if result.hasSuffix(blackItem) {
                                if let range = result.range(of: blackItem) {
                                    result.removeSubrange(range)
                                }
                            }
                            if let range = result.range(of: "\"") {
                                result.removeSubrange(range)
                            }
                            if tmpKey.hasPrefix(blackItem) {
                                if let range = tmpKey.range(of: blackItem) {
                                    tmpKey.removeSubrange(range)
                                }
                            }
                            if tmpKey.hasSuffix(blackItem) {
                                if let range = tmpKey.range(of: blackItem) {
                                    tmpKey.removeSubrange(range)
                                }
                            }
                        }
//                        if tmpKey.contains("*") {
//                            tmpKey = tmpKey.replacingOccurrences(of: "*", with: "%@")
//                        }
//                        if result.contains("*") {
//                            result = result.replacingOccurrences(of: "*", with: "%@")
//                        }
                        text.append("\"\(tmpKey)\" = \"\(result)\";\n")
                    }
                    try text.write(toFile: tempPath, atomically: true, encoding: .utf8)
                    Thread.sleep(forTimeInterval: 1)
                }
                print("finish")
            }
        }
    }
}

extension ViewController: XMLParserDelegate {
    func parserDidStartDocument(_ parser: XMLParser) {
        print(#function)
    }
    func parserDidEndDocument(_ parser: XMLParser) {
        print(#function)
        print("keys.count = \(keys.count)")
        print("values.count = \(values.count)")
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if string.hasPrefix("\n") { return }
        tempString.append(string)
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        print(attributeDict)
        guard let key = attributeDict["name"] else {
            return }
        keys.append(key)
        android_supplementWord_keys.append(key)
        tempString = ""
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elementName == "string" else {
            return
        }
        values.append(tempString)
    }
}
