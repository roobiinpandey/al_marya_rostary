/**
 * ═══════════════════════════════════════════════════════════════════════════
 * 🏢 ENTERPRISE EXPORT UTILITY - Al Marya Rostery
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * Professional-grade export system for PDF, Excel, and CSV reports
 * Features:
 * - PDF: Multi-page, branded, charts embedded, executive summaries
 * - Excel: Multi-sheet, formulas, formatting, pivot-ready
 * - CSV: UTF-8 BOM, proper escaping, import-ready
 * 
 * Version: 1.0.0
 * Date: November 11, 2025
 * ═══════════════════════════════════════════════════════════════════════════
 */

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

const ExportConfig = {
    // Company Branding
    company: {
        name: "Al Marya Rostery",
        arabicName: "محمصة المرايا",
        logo: "☕", // Unicode coffee emoji (will be enhanced with actual logo)
        tagline: "Premium Coffee Trading & Roastery",
        colors: {
            primary: "#8B4513",    // Coffee brown
            secondary: "#D4AF37",  // Gold
            accent: "#2C1810",     // Dark brown
            text: "#333333"
        }
    },
    
    // PDF Settings
    pdf: {
        orientation: 'portrait', // 'portrait' or 'landscape'
        unit: 'mm',
        format: 'a4',
        margins: { top: 20, right: 15, bottom: 20, left: 15 },
        fontSize: {
            title: 24,
            heading: 16,
            subheading: 12,
            body: 10,
            small: 8
        }
    },
    
    // Excel Settings
    excel: {
        creator: "Al Marya Rostery Admin Panel",
        sheetNames: {
            summary: "Executive Summary",
            details: "Detailed Data",
            charts: "Charts & Analytics",
            raw: "Raw Data"
        },
        defaultColumnWidth: 15,
        headerStyle: {
            font: { bold: true, color: { rgb: "FFFFFF" } },
            fill: { fgColor: { rgb: "8B4513" } },
            alignment: { horizontal: "center", vertical: "center" }
        }
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// PDF EXPORT UTILITY
// ═══════════════════════════════════════════════════════════════════════════

class PDFExporter {
    constructor(options = {}) {
        const { jsPDF } = window.jspdf;
        this.doc = new jsPDF(ExportConfig.pdf);
        this.options = {
            title: options.title || 'Report',
            subtitle: options.subtitle || '',
            period: options.period || this.getCurrentPeriod(),
            includeCharts: options.includeCharts !== false,
            includeInsights: options.includeInsights !== false,
            ...options
        };
        this.currentY = ExportConfig.pdf.margins.top;
        this.pageNumber = 1;
    }

    getCurrentPeriod() {
        const now = new Date();
        return now.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
        });
    }

    addHeader() {
        const { doc } = this;
        const { company, pdf } = ExportConfig;
        
        // Logo (large emoji for now)
        doc.setFontSize(32);
        doc.text(company.logo, 15, 15);
        
        // Company Name
        doc.setFontSize(pdf.fontSize.heading);
        doc.setTextColor(company.colors.primary);
        doc.setFont(undefined, 'bold');
        doc.text(company.name, 30, 12);
        
        // Arabic Name
        doc.setFontSize(pdf.fontSize.small);
        doc.setTextColor(company.colors.secondary);
        doc.text(company.arabicName, 30, 17);
        
        // Report Title
        doc.setFontSize(pdf.fontSize.title);
        doc.setTextColor(company.colors.text);
        doc.setFont(undefined, 'bold');
        doc.text(this.options.title, 15, 30);
        
        // Subtitle & Period
        doc.setFontSize(pdf.fontSize.body);
        doc.setFont(undefined, 'normal');
        doc.setTextColor('#666666');
        if (this.options.subtitle) {
            doc.text(this.options.subtitle, 15, 37);
        }
        doc.text(`Period: ${this.options.period}`, 15, 43);
        doc.text(`Generated: ${new Date().toLocaleString()}`, 15, 48);
        
        // Horizontal line
        doc.setDrawColor(company.colors.secondary);
        doc.setLineWidth(0.5);
        doc.line(15, 52, 195, 52);
        
        this.currentY = 58;
    }

    addFooter() {
        const { doc } = this;
        const pageHeight = doc.internal.pageSize.height;
        
        // Page number
        doc.setFontSize(ExportConfig.pdf.fontSize.small);
        doc.setTextColor('#999999');
        doc.text(
            `Page ${this.pageNumber}`,
            105,
            pageHeight - 10,
            { align: 'center' }
        );
        
        // Company footer
        doc.text(
            `${ExportConfig.company.name} - ${ExportConfig.company.tagline}`,
            105,
            pageHeight - 6,
            { align: 'center' }
        );
    }

    addSection(title, content = null) {
        this.checkPageBreak(20);
        
        const { doc } = this;
        
        // Section title
        doc.setFontSize(ExportConfig.pdf.fontSize.heading);
        doc.setTextColor(ExportConfig.company.colors.primary);
        doc.setFont(undefined, 'bold');
        doc.text(title, 15, this.currentY);
        
        this.currentY += 8;
        
        // Horizontal line under section
        doc.setDrawColor(ExportConfig.company.colors.secondary);
        doc.setLineWidth(0.3);
        doc.line(15, this.currentY, 195, this.currentY);
        
        this.currentY += 6;
        
        // Content
        if (content) {
            doc.setFontSize(ExportConfig.pdf.fontSize.body);
            doc.setTextColor(ExportConfig.company.colors.text);
            doc.setFont(undefined, 'normal');
            
            if (typeof content === 'string') {
                const lines = doc.splitTextToSize(content, 165);
                doc.text(lines, 15, this.currentY);
                this.currentY += lines.length * 5;
            }
        }
    }

    addExecutiveSummary(data) {
        this.addSection('EXECUTIVE SUMMARY');
        
        const { doc } = this;
        const metrics = [
            { label: 'Total Revenue', value: data.totalRevenue || 'N/A', icon: '💰' },
            { label: 'Total Orders', value: data.totalOrders || 'N/A', icon: '📦' },
            { label: 'Average Order Value', value: data.avgOrderValue || 'N/A', icon: '📊' },
            { label: 'Growth vs Last Period', value: data.growth || 'N/A', icon: '📈' }
        ];
        
        doc.setFontSize(ExportConfig.pdf.fontSize.body);
        metrics.forEach((metric, index) => {
            this.checkPageBreak(8);
            
            doc.setFont(undefined, 'bold');
            doc.text(`${metric.icon} ${metric.label}:`, 20, this.currentY);
            
            doc.setFont(undefined, 'normal');
            doc.text(String(metric.value), 100, this.currentY);
            
            this.currentY += 7;
        });
        
        this.currentY += 5;
    }

    addKeyInsights(insights) {
        if (!insights || insights.length === 0) return;
        
        this.addSection('KEY INSIGHTS');
        
        const { doc } = this;
        doc.setFontSize(ExportConfig.pdf.fontSize.body);
        
        insights.forEach((insight, index) => {
            this.checkPageBreak(6);
            
            doc.setFont(undefined, 'normal');
            doc.text(`• ${insight}`, 20, this.currentY);
            this.currentY += 6;
        });
        
        this.currentY += 5;
    }

    addTable(data, columns) {
        this.checkPageBreak(40);
        
        const tableData = data.map(row => 
            columns.map(col => row[col.field] || '')
        );
        
        this.doc.autoTable({
            startY: this.currentY,
            head: [columns.map(col => col.header)],
            body: tableData,
            theme: 'striped',
            headStyles: {
                fillColor: [139, 69, 19], // Coffee brown
                textColor: [255, 255, 255],
                fontStyle: 'bold',
                halign: 'center'
            },
            alternateRowStyles: {
                fillColor: [245, 245, 245]
            },
            styles: {
                fontSize: ExportConfig.pdf.fontSize.body,
                cellPadding: 3,
                overflow: 'linebreak'
            },
            columnStyles: columns.reduce((acc, col, index) => {
                if (col.align) {
                    acc[index] = { halign: col.align };
                }
                return acc;
            }, {}),
            margin: { left: 15, right: 15 },
            didDrawPage: (data) => {
                if (data.pageNumber > this.pageNumber) {
                    this.pageNumber = data.pageNumber;
                    this.addFooter();
                }
            }
        });
        
        this.currentY = this.doc.lastAutoTable.finalY + 10;
    }

    async addChart(chartElement) {
        if (!this.options.includeCharts) return;
        
        this.checkPageBreak(100);
        
        try {
            // Convert chart to image
            const canvas = chartElement.querySelector('canvas') || chartElement;
            const imgData = canvas.toDataURL('image/png');
            
            // Add to PDF
            const imgWidth = 170;
            const imgHeight = 80;
            this.doc.addImage(imgData, 'PNG', 15, this.currentY, imgWidth, imgHeight);
            
            this.currentY += imgHeight + 10;
        } catch (error) {
            console.error('Error adding chart to PDF:', error);
        }
    }

    addRecommendations(recommendations) {
        if (!recommendations || recommendations.length === 0) return;
        
        this.addSection('RECOMMENDATIONS');
        
        const { doc } = this;
        doc.setFontSize(ExportConfig.pdf.fontSize.body);
        
        recommendations.forEach((rec, index) => {
            this.checkPageBreak(6);
            
            doc.setFont(undefined, 'normal');
            doc.text(`• ${rec}`, 20, this.currentY);
            this.currentY += 6;
        });
    }

    checkPageBreak(requiredSpace) {
        const pageHeight = this.doc.internal.pageSize.height;
        const bottomMargin = ExportConfig.pdf.margins.bottom;
        
        if (this.currentY + requiredSpace > pageHeight - bottomMargin) {
            this.addFooter();
            this.doc.addPage();
            this.pageNumber++;
            this.currentY = ExportConfig.pdf.margins.top;
        }
    }

    generate(filename = null) {
        // Add final footer
        this.addFooter();
        
        // Generate filename if not provided
        if (!filename) {
            const timestamp = new Date().toISOString().slice(0, 10);
            filename = `${this.options.title.replace(/\s+/g, '_')}_${timestamp}.pdf`;
        }
        
        // Save PDF
        this.doc.save(filename);
    }

    getBlob() {
        return this.doc.output('blob');
    }

    getDataUri() {
        return this.doc.output('datauristring');
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXCEL EXPORT UTILITY
// ═══════════════════════════════════════════════════════════════════════════

class ExcelExporter {
    constructor(options = {}) {
        this.options = {
            filename: options.filename || 'export',
            sheetName: options.sheetName || 'Data',
            multiSheet: options.multiSheet !== false,
            includeFormulas: options.includeFormulas !== false,
            includeFormatting: options.includeFormatting !== false,
            ...options
        };
        
        this.workbook = XLSX.utils.book_new();
        this.workbook.Props = {
            Title: this.options.filename,
            Subject: "Al Marya Rostery Report",
            Author: ExportConfig.excel.creator,
            CreatedDate: new Date()
        };
    }

    addSummarySheet(data) {
        const summaryData = [
            ['Al Marya Rostery - Executive Summary'],
            ['Generated:', new Date().toLocaleString()],
            ['Period:', this.options.period || 'Current'],
            [],
            ['Metric', 'Value', 'Change'],
            ['Total Revenue', data.totalRevenue || 0, data.revenueChange || 'N/A'],
            ['Total Orders', data.totalOrders || 0, data.ordersChange || 'N/A'],
            ['Total Customers', data.totalCustomers || 0, data.customersChange || 'N/A'],
            ['Average Order Value', data.avgOrderValue || 0, data.avgChange || 'N/A'],
            [],
            ['Key Metrics'],
            ['Conversion Rate:', data.conversionRate || 'N/A'],
            ['Customer Retention:', data.retention || 'N/A'],
            ['Top Product:', data.topProduct || 'N/A'],
            ['Best Day:', data.bestDay || 'N/A']
        ];
        
        const ws = XLSX.utils.aoa_to_sheet(summaryData);
        
        // Set column widths
        ws['!cols'] = [
            { wch: 30 },
            { wch: 20 },
            { wch: 15 }
        ];
        
        // Merge title cells
        ws['!merges'] = [
            { s: { r: 0, c: 0 }, e: { r: 0, c: 2 } }
        ];
        
        // Add styling (if supported)
        this.styleHeaderRow(ws, 5);
        
        XLSX.utils.book_append_sheet(this.workbook, ws, ExportConfig.excel.sheetNames.summary);
    }

    addDataSheet(data, columns, sheetName = null) {
        // Prepare header row
        const headers = columns.map(col => col.header || col.field);
        
        // Prepare data rows
        const rows = data.map(row => 
            columns.map(col => {
                const value = row[col.field];
                
                // Format based on type
                if (col.type === 'currency' && typeof value === 'number') {
                    return value;
                }
                if (col.type === 'date' && value) {
                    return new Date(value);
                }
                if (col.type === 'number' && typeof value === 'number') {
                    return value;
                }
                
                return value || '';
            })
        );
        
        // Combine headers and rows
        const sheetData = [headers, ...rows];
        
        // Create worksheet
        const ws = XLSX.utils.aoa_to_sheet(sheetData);
        
        // Set column widths
        const colWidths = columns.map(col => ({
            wch: col.width || ExportConfig.excel.defaultColumnWidth
        }));
        ws['!cols'] = colWidths;
        
        // Add filters
        ws['!autofilter'] = { ref: XLSX.utils.encode_range({
            s: { r: 0, c: 0 },
            e: { r: rows.length, c: columns.length - 1 }
        })};
        
        // Style header row
        this.styleHeaderRow(ws, 1);
        
        // Format currency columns
        columns.forEach((col, colIndex) => {
            if (col.type === 'currency') {
                for (let rowIndex = 1; rowIndex <= rows.length; rowIndex++) {
                    const cellRef = XLSX.utils.encode_cell({ r: rowIndex, c: colIndex });
                    if (ws[cellRef]) {
                        ws[cellRef].z = '"AED "#,##0.00';
                    }
                }
            }
        });
        
        // Add totals row if requested
        if (this.options.includeTotals) {
            this.addTotalsRow(ws, columns, rows.length + 1);
        }
        
        XLSX.utils.book_append_sheet(
            this.workbook, 
            ws, 
            sheetName || this.options.sheetName
        );
    }

    addTotalsRow(ws, columns, rowIndex) {
        columns.forEach((col, colIndex) => {
            const cellRef = XLSX.utils.encode_cell({ r: rowIndex, c: colIndex });
            
            if (colIndex === 0) {
                ws[cellRef] = { t: 's', v: 'TOTAL' };
            } else if (col.type === 'number' || col.type === 'currency') {
                // Add SUM formula
                const startCell = XLSX.utils.encode_cell({ r: 1, c: colIndex });
                const endCell = XLSX.utils.encode_cell({ r: rowIndex - 1, c: colIndex });
                ws[cellRef] = { 
                    t: 'n', 
                    f: `SUM(${startCell}:${endCell})`,
                    z: col.type === 'currency' ? '"AED "#,##0.00' : '#,##0'
                };
            }
        });
    }

    styleHeaderRow(ws, rowIndex) {
        // Note: XLSX doesn't support full styling without xlsx-style
        // This is a placeholder for when styling is available
        // For now, we just ensure headers are present
    }

    addPivotSheet(data, rowField, valueField, sheetName = 'Pivot') {
        // Create pivot table data
        const pivot = {};
        
        data.forEach(row => {
            const key = row[rowField];
            if (!pivot[key]) {
                pivot[key] = 0;
            }
            pivot[key] += parseFloat(row[valueField] || 0);
        });
        
        // Convert to array
        const pivotData = [
            [rowField, valueField],
            ...Object.entries(pivot).map(([key, value]) => [key, value])
        ];
        
        const ws = XLSX.utils.aoa_to_sheet(pivotData);
        ws['!cols'] = [{ wch: 30 }, { wch: 15 }];
        
        XLSX.utils.book_append_sheet(this.workbook, ws, sheetName);
    }

    generate() {
        const timestamp = new Date().toISOString().slice(0, 10);
        const filename = `${this.options.filename}_${timestamp}.xlsx`;
        
        XLSX.writeFile(this.workbook, filename);
    }

    getBlob() {
        const wbout = XLSX.write(this.workbook, { bookType: 'xlsx', type: 'array' });
        return new Blob([wbout], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CSV EXPORT UTILITY
// ═══════════════════════════════════════════════════════════════════════════

class CSVExporter {
    constructor(options = {}) {
        this.options = {
            filename: options.filename || 'export',
            delimiter: options.delimiter || ',',
            includeHeaders: options.includeHeaders !== false,
            encoding: options.encoding || 'utf-8',
            ...options
        };
    }

    escapeValue(value) {
        if (value === null || value === undefined) return '';
        
        const str = String(value);
        
        // If contains delimiter, newline, or quotes, wrap in quotes
        if (str.includes(this.options.delimiter) || 
            str.includes('\n') || 
            str.includes('"')) {
            return '"' + str.replace(/"/g, '""') + '"';
        }
        
        return str;
    }

    generate(data, columns) {
        const rows = [];
        
        // Add headers
        if (this.options.includeHeaders) {
            const headers = columns.map(col => col.header || col.field);
            rows.push(headers.map(h => this.escapeValue(h)).join(this.options.delimiter));
        }
        
        // Add data rows
        data.forEach(row => {
            const values = columns.map(col => this.escapeValue(row[col.field]));
            rows.push(values.join(this.options.delimiter));
        });
        
        const csvContent = rows.join('\n');
        
        // Create blob with BOM for Excel compatibility
        const BOM = '\uFEFF';
        const blob = new Blob([BOM + csvContent], { type: 'text/csv;charset=utf-8;' });
        
        // Download
        const timestamp = new Date().toISOString().slice(0, 10);
        const filename = `${this.options.filename}_${timestamp}.csv`;
        
        this.downloadBlob(blob, filename);
    }

    downloadBlob(blob, filename) {
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        
        link.setAttribute('href', url);
        link.setAttribute('download', filename);
        link.style.visibility = 'hidden';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        URL.revokeObjectURL(url);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPORT HELPERS
// ═══════════════════════════════════════════════════════════════════════════

const ExportHelpers = {
    /**
     * Format currency for display
     */
    formatCurrency(amount, currency = 'AED') {
        if (typeof amount !== 'number') return 'N/A';
        return `${currency} ${amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
    },

    /**
     * Format date for display
     */
    formatDate(date, format = 'long') {
        if (!date) return 'N/A';
        const d = new Date(date);
        
        if (format === 'long') {
            return d.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
            });
        } else if (format === 'short') {
            return d.toLocaleDateString('en-US');
        } else {
            return d.toISOString().slice(0, 10);
        }
    },

    /**
     * Calculate percentage change
     */
    calculateChange(current, previous) {
        if (!previous || previous === 0) return 'N/A';
        const change = ((current - previous) / previous) * 100;
        const sign = change >= 0 ? '+' : '';
        return `${sign}${change.toFixed(1)}%`;
    },

    /**
     * Generate insights from data
     */
    generateInsights(data) {
        const insights = [];
        
        if (data.bestDay) {
            insights.push(`Best performing day: ${data.bestDay}`);
        }
        
        if (data.topProduct) {
            insights.push(`Top selling product: ${data.topProduct}`);
        }
        
        if (data.growth && parseFloat(data.growth) > 0) {
            insights.push(`Revenue growth of ${data.growth} compared to previous period`);
        }
        
        if (data.peakHour) {
            insights.push(`Peak sales hour: ${data.peakHour}`);
        }
        
        if (data.retention && parseFloat(data.retention) > 60) {
            insights.push(`Strong customer retention at ${data.retention}%`);
        }
        
        return insights;
    },

    /**
     * Generate recommendations based on data
     */
    generateRecommendations(data) {
        const recommendations = [];
        
        if (data.lowStockItems && data.lowStockItems.length > 0) {
            recommendations.push(`Restock ${data.lowStockItems.length} items running low`);
        }
        
        if (data.topProduct) {
            recommendations.push(`Increase inventory for ${data.topProduct} (high demand)`);
        }
        
        if (data.peakHour) {
            recommendations.push(`Staff appropriately for peak hours around ${data.peakHour}`);
        }
        
        if (data.cartAbandonment && parseFloat(data.cartAbandonment) > 50) {
            recommendations.push('High cart abandonment - optimize checkout process');
        }
        
        return recommendations;
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// MAKE AVAILABLE GLOBALLY
// ═══════════════════════════════════════════════════════════════════════════

window.PDFExporter = PDFExporter;
window.ExcelExporter = ExcelExporter;
window.CSVExporter = CSVExporter;
window.ExportHelpers = ExportHelpers;
window.ExportConfig = ExportConfig;

console.log('✅ Enterprise Export Utilities loaded successfully');
