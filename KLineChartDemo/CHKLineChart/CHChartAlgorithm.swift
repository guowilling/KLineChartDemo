
import UIKit

public protocol CHChartAlgorithmProtocol {
    /// 传入 K 线数据模型集合, 完成指标数据计算
    ///
    /// - Parameter datas: K 线数据模型集合
    /// - Returns: 返回处理后的集合, 指标的计算结果记录在模型的 extVal 字典中
    func calculateIndex(_ items: [CHChartItem]) -> [CHChartItem]
}

public enum CHChartAlgorithm: CHChartAlgorithmProtocol {
    
    case none                       // 无算法
    case timeline                   // 时分
    case ma(Int)                    // 简单移动平均数
    case ema(Int)                   // 指数移动平均数
    case boll(Int, Int)             // 布林线
    case macd(Int, Int, Int)        // 指数平滑异同平均线
    case kdj(Int, Int, Int)         // 随机指标
    case sar(Int, CGFloat, CGFloat) // 停损转向操作点指标(判定周期，加速因子初值，加速因子最大值)
    case rsi(Int)                   // 相对强弱指标
    
    public func key(_ name: String = "") -> String {
        switch self {
        case .none:
            return ""
        case .timeline:
            return "\(CHSeriesKey.timeline)_\(name)"
        case .ma(let num):
            return "\(CHSeriesKey.ma)_\(num)_\(name)"
        case .ema(let num):
            return "\(CHSeriesKey.ema)_\(num)_\(name)"
        case .boll(_, _):
            return "\(CHSeriesKey.boll)_\(name)"
        case .macd(_, _, _):
            return "\(CHSeriesKey.macd)_\(name)"
        case .kdj(_, _, _):
            return "\(CHSeriesKey.kdj)_\(name)"
        case .sar(_, _, _):
            return "\(CHSeriesKey.sar)\(name)"
        case .rsi(let num):
            return "\(CHSeriesKey.rsi)_\(num)_\(name)"
        }
    }
    
    public func calculateIndex(_ items: [CHChartItem]) -> [CHChartItem] {
        switch self {
        case .none:
            return items
        case .timeline:
            return self.calculateTimeline(items: items)
        case let .ma(num):
            return self.calculateMA(num, items: items)
        case let .ema(num):
            return self.calculateEMA(num, items: items)
        case let .boll(num, k):
            return self.calculateBOLL(num, k: k, items: items)
        case let .macd(p1, p2, p3):
            return self.calculateMACD(p1, p2: p2, p3: p3, items: items)
        case let .kdj(p1, p2, p3):
            return self.calculateKDJ(p1, p2: p2, p3: p3, items: items)
        case let .sar(num, minAF, maxAF):
            return self.calculateSAR(num,minAF: minAF, maxAF: maxAF, items: items)
        case let .rsi(num):
            return self.calculateRSI(num, items: items)
        }
    }
}

extension CHChartAlgorithm {
    // MARK: - Timeline
    fileprivate func calculateTimeline(items: [CHChartItem]) -> [CHChartItem] {
        for (_, item) in items.enumerated() {
            item.extVal["\(self.key(CHSeriesKey.timeline))"] = item.closePrice
            item.extVal["\(self.key(CHSeriesKey.volume))"] = item.vol
        }
        return items
    }
}

extension CHChartAlgorithm {
    // MARK: - MA
    fileprivate func calculateMA(_ num: Int, items: [CHChartItem]) -> [CHChartItem] {
        for (index, item) in items.enumerated() {
            let value = self.getMAValue(num, index: index, items: items)
            item.extVal["\(self.key(CHSeriesKey.timeline))"] = value.0
            item.extVal["\(self.key(CHSeriesKey.volume))"] = value.1
        }
        return items
    }
    
    /// 计算移动平均线
    ///
    /// - Parameters:
    ///   - num: 多少天
    ///   - index: 数据索引
    ///   - items: 数据集合
    /// - Returns: MA(价格, 交易量)
    private func getMAValue(_ num: Int, index: Int, items: [CHChartItem]) -> (CGFloat?, CGFloat?) {
        var priceVal: CGFloat = 0
        var volVal: CGFloat = 0
        if index + 1 >= num {
            // index + 1 >= N, 累计 N 天内的
            for i in stride(from: index, through: index + 1 - num, by: -1) {
                priceVal += items[i].closePrice
                volVal += items[i].vol
            }
            priceVal = priceVal / CGFloat(num)
            volVal = volVal / CGFloat(num)
            return (priceVal, volVal)
        } else {
            // index + 1 < N, 累计 index + 1 天内的
            for i in stride(from: index, through: 0, by: -1) {
                volVal += items[i].vol
                priceVal += items[i].closePrice
            }
            volVal = volVal / CGFloat(index + 1)
            priceVal = priceVal / CGFloat(index + 1)
            return (priceVal, volVal)
        }
    }
}

extension CHChartAlgorithm {
    // MARK: - EMA
    // EMA(N) = 2 / (N + 1 ) * (C - 昨日 EMA) + 昨日 EMA
    fileprivate func calculateEMA(_ num: Int, items: [CHChartItem]) -> [CHChartItem] {
        var prev_ema_price: CGFloat = 0
        var prev_ema_vol: CGFloat = 0
        for (index, item) in items.enumerated() {
            let c = items[index].closePrice
            let v = items[index].vol
            var ema_price: CGFloat = 0
            var ema_vol: CGFloat = 0
            if index > 0 {
                ema_price = prev_ema_price + (c - prev_ema_price) * 2 / (CGFloat(num) + 1)
                ema_vol = prev_ema_vol + (v - prev_ema_vol) * 2 / (CGFloat(num) + 1)
            } else {
                ema_price = c
                ema_vol = v
            }
            item.extVal["\(self.key(CHSeriesKey.timeline))"] = ema_price
            item.extVal["\(self.key(CHSeriesKey.volume))"] = ema_vol
            prev_ema_price = ema_price
            prev_ema_vol = ema_vol
        }
        return items
    }
}

extension CHChartAlgorithm {
    // MARK: - BOLL
    
    /// 计算公式:
    /// 中轨线 = N 日的移动平均线
    /// 上轨线 = 中轨线 + 两倍的标准差
    /// 下轨线 = 中轨线 - 两倍的标准差
    
    /// 计算过程:
    /// 1.计算 MA
    /// MA = N 日内的收盘价之和 ÷ N
    /// 2.计算标准差 MD
    /// MD = 平方根 N 日的(C－MA)的两次方之和除以 N
    /// 3.计算 MB、UP、DN 线
    /// MB = (N)日的 MA
    /// UP = MB + k * MD
    /// DN = MB - k * MD
    /// K 为参数, 可根据股票的特性来做相应的调整, 一般默认为2
    
    /// 计算布林线
    ///
    /// - Parameters:
    ///   - num: 天数
    ///   - k: 参数默认为2
    ///   - items: 待处理的数据
    /// - Returns: 处理后的数据
    fileprivate func calculateBOLL(_ num: Int, k: Int = 2, items: [CHChartItem]) -> [CHChartItem] {
        var md: CGFloat = 0, mb: CGFloat = 0, up: CGFloat = 0, dn: CGFloat = 0
        for (index, item) in items.enumerated() {
            md = self.getBOLLSTDValue(num, index: index, items: items)
            mb = self.getMA(num, index: index, items: items).0 ?? 0
            up = mb + CGFloat(k) * md
            dn = mb - CGFloat(k) * md
            item.extVal["\(self.key("BOLL"))"] = mb
            item.extVal["\(self.key("UB"))"] = up
            item.extVal["\(self.key("LB"))"] = dn
        }
        return items
    }
    
    /// 计算布林线中的 MA 平方差
    private func getBOLLSTDValue(_ num: Int, index: Int, items: [CHChartItem]) -> CGFloat {
        var dx: CGFloat = 0, md: CGFloat = 0
        let ma = self.getMA(num, index: index, items: items).0 ?? 0
        if index + 1 >= num {
            // 计算 N 日的平方差
            for i in stride(from: index, through: index + 1 - num, by: -1) {
                dx += pow(items[i].closePrice - ma, 2)
            }
            md = dx / CGFloat(num)
        } else {
            // 计算 index + 1 日的平方差
            for i in stride(from: index, through: 0, by: -1) {
                dx += pow(items[i].closePrice - ma, 2)
            }
            md = dx / CGFloat(index + 1)
        }
        md = pow(md, 0.5)
        return md
    }
}

extension CHChartAlgorithm {
    // MARK: - MACD
    fileprivate func calculateMACD(_ p1: Int, p2: Int,p3: Int, items: [CHChartItem]) -> [CHChartItem] {
        var pre_dea: CGFloat = 0
        for (index, item) in items.enumerated() {
            // EMA（p1）= 2 /（p1+1）*（C-昨日EMA）+ 昨日EMA
            let (ema1, _) = self.getEMA(p1, index: index, items: items)
            // EMA（p2）= 2 /（p2+1）*（C-昨日EMA）+ 昨日EMA
            let (ema2, _) = self.getEMA(p2, index: index, items: items)
            if ema1 != nil && ema2 != nil {
                // DIF = 今日EMA（p1）- 今日EMA（p2）
                let dif = ema1! - ema2!
                // DEA（p3）= 2 /（p3+1）*（DIF-昨日DEA）+昨日DEA
                let dea = pre_dea + (dif - pre_dea) * 2 / (CGFloat(p3) + 1)
                // BAR = 2 * (DIF－DEA)
                let bar = 2 * (dif - dea)
                item.extVal["\(self.key("DIF"))"] = dif
                item.extVal["\(self.key("DEA"))"] = dea
                item.extVal["\(self.key("BAR"))"] = bar
                pre_dea = dea
            }
        }
        return items
    }
}

extension CHChartAlgorithm {
    // MARK: - KDJ
    fileprivate func calculateKDJ(_ p1: Int, p2: Int,p3: Int, items: [CHChartItem]) -> [CHChartItem] {
        var prev_k: CGFloat = 50
        var prev_d: CGFloat = 50
        for (index, item) in items.enumerated() {
            // RSV
            if let rsv = self.getRSVValue(p1, index: index, items: items) {
                // KDJ
                let k: CGFloat = (2 * prev_k + rsv) / 3
                let d: CGFloat = (2 * prev_d + k) / 3
                let j: CGFloat = 3 * k - 2 * d
                prev_k = k
                prev_d = d
                item.extVal["\(self.key("K"))"] = k
                item.extVal["\(self.key("D"))"] = d
                item.extVal["\(self.key("J"))"] = j
            }
        }
        return items
    }
    
    private func getRSVValue(_ num: Int, index: Int, items: [CHChartItem]) -> CGFloat? {
        var rsv: CGFloat = 0
        let c = items[index].closePrice
        var h = items[index].highPrice
        var l = items[index].lowPrice
        let tempClosure: (Int) -> Void = { (i) -> Void in
            let item = items[i]
            if item.highPrice > h {
                h = item.highPrice
            }
            if item.lowPrice < l {
                l = item.lowPrice
            }
        }
        if index + 1 >= num {
            // 计算 num 天数内最低价和最高价
            for i in stride(from: index, through: index + 1 - num, by: -1) {
                tempClosure(i)
            }
        } else {
            // 计算 index 天数内最低价和最高价
            for i in stride(from: index, through: 0, by: -1) {
                tempClosure(i)
            }
        }
        if h != l {
            rsv = (c - l) / (h - l) * 100
        }
        return rsv
    }
}

extension CHChartAlgorithm {
    // MARK: - SAR
    
    /// - Parameter num: 基准周期数 N
    /// - Parameter minAF: 加速因子 A F最小值(初始值)
    /// - Parameter maxAF: 加速因子 AF 最大值
    /// - Parameter datas: 待处理的数据
    /// - Returns: 处理后的数据
    fileprivate func calculateSAR(_ num: Int, minAF: CGFloat, maxAF: CGFloat, items: [CHChartItem]) -> [CHChartItem] {
        var sar: CGFloat = 0, af: CGFloat = minAF, ep: CGFloat = 0
        var pre_data: CHChartItem!
        var isUP: Bool = true
        
        // SAR 指标至少2条数据才显示
        guard num >= 2 && items.count >= 2 else {
            return items
        }
        
        /// 初始值 SAR(T0) 的确定
        if items[1].closePrice > items[0].closePrice {
            // 上涨趋势, SAR(T0) 为 T0 周期的最低价
            sar = items[0].lowPrice
            isUP = true
        } else {
            // 下跌趋势, SAR(T0) 为 T0 周期的最高价
            sar = items[0].highPrice
            isUP = false
        }
        
        // 记录第1日
        pre_data = items[0]
        
        for (index, data) in items.enumerated() {
            if index > 0 { // 忽略第一天
                // 确定今天的 SAR 值
                let finalSAR = self.getFinalSARValue(num: num, sar: sar, index: index, isUP: isUP, items: items)
                
                // 出现行情反转, 重置 AF 加速因子
                if isUP != finalSAR.1 {
                    af = minAF
                }
                sar = finalSAR.0
                isUP = finalSAR.1
            }
            data.extVal["\(self.key())"] = sar
            
            // 预算下一天的 SAR 值
            // SAR(Tn) = SAR(Tn-1) + AF(Tn) * [EP(Tn-1) - SAR(Tn-1)]
            // SAR(1) = SAR(0) + AF(1) * [EP(0) - SAR(0)]
            
            // 极点价 EP 的确定
            if isUP {
                // 上涨趋势, EP(Tn-1) 为 Tn-1 周期的最高价
                ep = pre_data.highPrice
            } else {
                // 下跌趋势, EP(Tn-1) 为 Tn-1 周期的最低价
                ep = pre_data.lowPrice
            }
            
            /// 加速因子 AF 的确定
            if isUP {
                if data.highPrice > pre_data.highPrice {
                    af = af + minAF
                }
            } else {
                if data.lowPrice < pre_data.lowPrice {
                    af = af + minAF
                }
            }
            if af > maxAF {
                af = maxAF
            }
            
            sar = sar + af * (ep - sar)
            
            // 记录明天的 SAR 值
            data.extVal["\(self.key("tomorrow"))"] = sar
            
            pre_data = data
        }
        
        return items
    }
    
    /// 确定当天的 SAR 值
    ///
    /// - Parameters:
    ///   - num: 趋势判断周期
    ///   - sar: 预算的 SAR 值
    ///   - index: 该周期位置
    ///   - isUP: 趋势
    ///   - datas: 数据集合
    /// - Returns: (SAR 最终值, 是否行情反转)
    func getFinalSARValue(num: Int, sar: CGFloat, index: Int, isUP: Bool, items: [CHChartItem]) -> (CGFloat, Bool) {
        var finalSAR: CGFloat = sar
        var finalIsUP: Bool = isUP
        var start = index
        if isUP {
            if sar > items[index].closePrice {
                // 以今天开始取前 num 天的最高价
                repeat {
                    finalSAR = max(items[start].highPrice, finalSAR)
                    start -= 1
                } while start >= max(index - num + 1, 0)
                finalIsUP = false
            }
        } else {
            if sar < items[index].closePrice {
                // 以今天开始取前 num 天的最低价
                repeat {
                    finalSAR = min(items[start].lowPrice, finalSAR)
                    start -= 1
                } while start >= max(index - num + 1, 0)
                finalIsUP = true
            }
        }
        return (finalSAR, finalIsUP)
    }
}

extension CHChartAlgorithm {
    // MARK: - RSI
    fileprivate func calculateRSI(_ num: Int, items: [CHChartItem]) -> [CHChartItem] {
        let defaultVal: CGFloat = 100
        let index = num - 1
        var sum: CGFloat = 0
        var dif: CGFloat = 0
        var rsi: CGFloat = 0
        for (i, item) in items.enumerated() {
            if (num == 0) {
                sum = 0
                dif = 0
            } else {
                let k = i - num + 1
                let wrs: [CGFloat] = self.getAandBValue(k, i, items: items)
                sum = wrs[0]
                dif = wrs[1]
            }
            if (dif != 0) {
                let h = sum + dif
                rsi = sum / h * 100
            } else {
                rsi = 100
            }
            if (i < index) {
                rsi = defaultVal
            }
            item.extVal["\(self.key(CHSeriesKey.timeline))"] = rsi
        }
        return items
    }
    
    fileprivate func getAandBValue(_ a: Int, _ b: Int, items: [CHChartItem]) -> [CGFloat] {
        var sum: CGFloat = 0
        var dif: CGFloat = 0
        var closeT: CGFloat!
        var closeY: CGFloat!
        var AandB: [CGFloat] = [0, 0]
        let nonnegative = a > 0 ? a : 0
        for index in nonnegative...b {
            if (index > nonnegative) {
                closeT = items[index].closePrice
                closeY = items[index - 1].closePrice
                let c: CGFloat = closeT - closeY
                if (c > 0) {
                    sum = sum + c
                } else {
                    dif = sum + c
                }
                dif = abs(dif)
            }
        }
        AandB[0] = sum
        AandB[1] = dif
        return AandB
    }
}

extension CHChartAlgorithm {
    fileprivate func getEMA(_ num: Int, index: Int, items: [CHChartItem]) -> (CGFloat?, CGFloat?) {
        let ema = CHChartAlgorithm.ema(num)
        let item = items[index]
        let ema_price = item.extVal["\(ema.key(CHSeriesKey.timeline))"]
        let ema_vol = item.extVal["\(ema.key(CHSeriesKey.volume))"]
        return (ema_price, ema_vol)
    }
    
    fileprivate func getMA(_ num: Int, index: Int, items: [CHChartItem]) -> (CGFloat?, CGFloat?) {
        let ma = CHChartAlgorithm.ma(num)
        let item = items[index]
        let ma_price = item.extVal["\(ma.key(CHSeriesKey.timeline))"]
        let ma_vol = item.extVal["\(ma.key(CHSeriesKey.volume))"]
        return (ma_price, ma_vol)
    }
}
