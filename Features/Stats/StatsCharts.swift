
import SwiftUI
import DGCharts

struct WeeklySavingsBarChart: UIViewRepresentable {
    var values: [Double]

    func makeUIView(context: Context) -> BarChartView {
        let chart = BarChartView()
        chart.legend.enabled = false
        chart.rightAxis.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.granularity = 1
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawGridLinesEnabled = true
        chart.leftAxis.gridColor = UIColor.systemGray5
        chart.extraTopOffset = 8
        chart.extraBottomOffset = 4
        return chart
    }

    func updateUIView(_ chart: BarChartView, context: Context) {
        let entries = values.enumerated().map { BarChartDataEntry(x: Double($0.offset), y: $0.element) }
        let set = BarChartDataSet(entries: entries)
        set.colors = [NSUIColor.systemBlue]
        set.drawValuesEnabled = false
        let data = BarChartData(dataSet: set)
        data.barWidth = 0.5
        chart.data = data
        chart.xAxis.valueFormatter = WeekDayAxisFormatter()
        chart.animate(yAxisDuration: 0.3)
    }
}

private final class WeekDayAxisFormatter: NSObject, AxisValueFormatter {
    private let labels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        let i = Int(value)
        guard i >= 0, i < labels.count else { return "" }
        return labels[i]
    }
}



struct MonthlyDynamicsLineChart: UIViewRepresentable {
    var values: [Double]
    var monthLabels: [String]

    func makeUIView(context: Context) -> LineChartView {
        let chart = LineChartView()
        chart.legend.enabled = false
        chart.rightAxis.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.granularity = 1
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawGridLinesEnabled = true
        chart.leftAxis.gridColor = UIColor.systemGray5
        chart.extraTopOffset = 8
        chart.extraBottomOffset = 4
        return chart
    }

    func updateUIView(_ chart: LineChartView, context: Context) {
        let entries = values.enumerated().map { LineChartDataEntry(x: Double($0.offset), y: $0.element) }
        let set = LineChartDataSet(entries: entries)
        set.colors = [NSUIColor.systemBlue]
        set.setCircleColor(NSUIColor.systemBlue)
        set.lineWidth = 2
        set.circleRadius = 4
        set.drawValuesEnabled = false
        set.mode = .linear
        chart.data = LineChartData(dataSet: set)
        chart.xAxis.valueFormatter = MonthAxisFormatter(labels: monthLabels)
        chart.animate(yAxisDuration: 0.3)
    }
}

private final class MonthAxisFormatter: NSObject, AxisValueFormatter {
    let labels: [String]
    init(labels: [String]) { self.labels = labels }
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        let i = Int(value)
        guard i >= 0, i < labels.count else { return "" }
        return labels[i]
    }
}

// MARK: - Сильные и слабые стороны (Radar Chart)

struct StatsRadarChart: UIViewRepresentable {
    
    var values: [Double]

    static let axisLabels = ["Дисциплина", "Планирование", "Дружба", "Активность", "Мотивация"]

    func makeUIView(context: Context) -> RadarChartView {
        let chart = RadarChartView()
        chart.legend.enabled = false
        chart.yAxis.axisMinimum = 0
        chart.yAxis.axisMaximum = 100
        chart.yAxis.drawLabelsEnabled = true
        chart.webLineWidth = 0.5
        chart.innerWebLineWidth = 0.5
        chart.extraTopOffset = 10
        chart.extraBottomOffset = 10
        return chart
    }

    func updateUIView(_ chart: RadarChartView, context: Context) {
        let entries = values.enumerated().map { RadarChartDataEntry(value: $0.element) }
        let set = RadarChartDataSet(entries: entries)
        set.colors = [NSUIColor.systemBlue]
        set.fillColor = NSUIColor.systemBlue.withAlphaComponent(0.3)
        set.drawFilledEnabled = true
        set.lineWidth = 2
        set.drawValuesEnabled = false
        chart.data = RadarChartData(dataSet: set)
        chart.xAxis.valueFormatter = RadarAxisFormatter(labels: Self.axisLabels)
        chart.animate(yAxisDuration: 0.3)
    }
}

private final class RadarAxisFormatter: NSObject, AxisValueFormatter {
    let labels: [String]
    init(labels: [String]) { self.labels = labels }
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        let i = Int(value)
        guard i >= 0, i < labels.count else { return "" }
        return labels[i]
    }
}
