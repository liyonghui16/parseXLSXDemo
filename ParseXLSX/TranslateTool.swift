//
//  TranslateTool.swift
//  ParseXLSX
//
//  Created by 30dayslyh on 2021/6/7.
//

import Foundation

public class TranslateTool {
    var tkk = "434674.96463358"
    var url = "https://translate.google.cn/translate_a/single"
    var token: String!
    var header = ["accept": "*/*",
                   "accept-language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
                   "cookie": "NID=188=M1p_rBfweeI_Z02d1MOSQ5abYsPfZogDrFjKwIUbmAr584bc9GBZkfDwKQ80cQCQC34zwD4ZYHFMUf4F59aDQLSc79_LcmsAihnW0Rsb1MjlzLNElWihv-8KByeDBblR2V1kjTSC8KnVMe32PNSJBQbvBKvgl4CTfzvaIEgkqss",
                   "referer": "https://translate.google.cn/",
                   "user-agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1",
                   "x-client-data": "CJK2yQEIpLbJAQjEtskBCKmdygEIqKPKAQi5pcoBCLGnygEI4qjKAQjxqcoBCJetygEIza3KAQ==",
    ]
    var reqData = ["client": "webapp",  // 基于网页访问服务器
                    "sl": "auto",  // 源语言,auto表示由谷歌自动识别
                    "tl": "en",  // 翻译的目标语言
                    "hl": "zh-CN",  // 界面语言选中文，毕竟URL是cn后缀
                    "dt": ["at", "bd", "ex", "ld", "md", "qca", "rw", "rm", "ss", "t"],  // dt表示要求服务器返回的数据类型
                    "otf": "2",
                    "ssel": "0",
                    "tsel": "0",
                    "kc": "1",
                    "tk": "",  // 谷歌服务器会核对的token
                    "q": ""
    ] as [String : Any]
    
    
    func translate(_ text: String, targetLanguageCode: String, completion:(String) -> Void) {
        getToken(text) { token in
            self.reqData["tk"] = token
            self.reqData["q"] = text.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)
            self.reqData["tl"] = targetLanguageCode
            let apiUrl = self.constructUrl()
            self.request(apiUrl, method: "GET", tmpHeader: self.header) { data in
                guard let data = data else { return }
                guard let dic =  try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any] else {return}
                print(dic)
            }
        }
    }
    
    func constructUrl() -> String {
        var base = ""
        for key in reqData.keys {
            if let o = reqData[key] as? [String] {
                var tmpTo = ""
                for s in o {
                    if s.count > 0 {
                        tmpTo = "\(tmpTo)&dt=\(s)"
                    } else {
                        tmpTo = "\(tmpTo)dt=\(s)"
                    }
                }
                base = "\(base)\(tmpTo)&"
            } else {
                base = "\(base)\(key)=\(reqData[key] ?? "")&"
            }
        }
        base = "\(url)?\(base)"
        return base
    }
    
    func getToken(_ text: String, completion: @escaping (String) -> Void) {
        let _tkk = tkk.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "tkk:", with: "")
        var urlString = "https://api.yooul.net/api/google/token?text=\(text)&tkk=\(_tkk)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        request(urlString, method: "GET", tmpHeader: nil) { data in
            guard let data = data else { return }
            guard let dic =  try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any] else {return}
            guard let token = dic["token"] as? String else {return}
            completion(token)
        }
    }
    
    func request(_ urlString: String, method: String, tmpHeader: [String:String]?, completion: @escaping (Data?)->Void) {
        guard let url = URL(string: urlString) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if tmpHeader != nil {
            req.allHTTPHeaderFields = tmpHeader!
        }
        let sessionDataTask = URLSession.shared.dataTask(with: req) { data, response, error in
            completion(data)
        }
        sessionDataTask.resume()
    }
    
}
