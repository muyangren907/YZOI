/* 乐中信奥 · 历年获奖人数图表 —— 纯 JS，由 index.md 的 <script> 标签包裹 */

(function () {
    'use strict';
  
    // ===== 1. 数据：年份 2021–2026，按实际填数字 =====
    var CONTESTS = {
      'CSP-J': {
        years:  ['2021', '2022', '2023', '2024', '2025', '2026'],
        first:  [0, 0, 0, 0, 5, 17],
        second: [0, 0, 0, 0, 3, 1],
        third:  [0, 0, 0, 0, 2, 1]
      },
      'CSP-S': {
        years:  ['2021', '2022', '2023', '2024', '2025', '2026'],
        first:  [0, 0, 0, 0, 1, 10],
        second: [0, 0, 0, 0, 6, 8],
        third:  [0, 0, 0, 0, 1, 1]
      },
      'NOIP': {
        years:  ['2021', '2022', '2023', '2024', '2025'],
        first:  [0, 0, 0, 0, 1],
        second: [0, 0, 0, 0, 4],
        third:  [0, 0, 0, 0, 4]
      },
      'NGOI': {
        years:  ['2021', '2022', '2023', '2024', '2025'],
        first:  [0, 0, 0, 0, 0],
        second: [0, 0, 0, 0, 0],
        third:  [0, 0, 0, 0, 2]
      },
      'NOI': {
        years:  ['2021', '2022', '2023', '2024', '2025', '2026'],
        first:  [0, 0, 0, 0, 0, 0],
        second: [0, 0, 0, 0, 0, 0],
        third:  [0, 0, 0, 0, 0, 0]
      },
      'WC': {
        years:  ['2021', '2022', '2023', '2024', '2025', '2026'],
        first:  [0, 0, 0, 0, 0, 0],
        second: [0, 0, 0, 0, 0, 0],
        third:  [0, 0, 0, 0, 0, 0]
      },
      'APIO': {
        years:  ['2021', '2022', '2023', '2024', '2025', '2026'],
        first:  [0, 0, 0, 0, 0, 0],
        second: [0, 0, 0, 0, 0, 0],
        third:  [0, 0, 0, 0, 0, 0]
      },
      'IOI': {
        years:  ['2021', '2022', '2023', '2024', '2025', '2026'],
        first:  [0, 0, 0, 0, 0, 0],
        second: [0, 0, 0, 0, 0, 0],
        third:  [0, 0, 0, 0, 0, 0]
      }
    };
  
    // ===== 2. 配色：金 / 银 / 铜 =====
    var GOLD   = { line: '#E8A800', glow: 'rgba(232,168,0,0.35)' };
    var SILVER = { line: '#8C97A8', glow: 'rgba(140,151,168,0.35)' };
    var BRONZE = { line: '#C4703A', glow: 'rgba(196,112,58,0.35)' };
  
    var chart = null;
  
    // ===== 3. ECharts 动态加载：本地优先 + 多 CDN 回退 =====
    function loadECharts() {
      return new Promise(function (resolve, reject) {
        if (window.echarts) { resolve(); return; }
        var sources = [
          '/assets/js/echarts.min.js',
          'https://cdn.bootcdn.net/ajax/libs/echarts/5.5.1/echarts.min.js',
          'https://lib.baomitu.com/echarts/5.5.1/echarts.min.js',
          'https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js',
          'https://unpkg.com/echarts@5/dist/echarts.min.js'
        ];
        var i = 0;
        function next() {
          if (i >= sources.length) {
            reject(new Error('ECharts 所有源均加载失败，请下载 echarts.min.js 到 assets/js/ 目录'));
            return;
          }
          var s = document.createElement('script');
          s.src = sources[i++];
          s.onload = function () { window.echarts ? resolve() : next(); };
          s.onerror = next;
          document.head.appendChild(s);
        }
        next();
      });
    }
  
    // ===== 4. 系列生成（smooth: false = 直线折线） =====
    function makeSeries(name, data, c) {
      return {
        name: name,
        type: 'line',
        smooth: false,
        symbol: 'circle',
        symbolSize: 9,
        data: data,
        lineStyle: { width: 3, color: c.line, shadowColor: c.glow, shadowBlur: 12 },
        itemStyle: { color: c.line, borderColor: '#fff', borderWidth: 2, shadowColor: c.glow, shadowBlur: 8 },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: c.glow },
            { offset: 1, color: 'rgba(0,0,0,0)' }
          ])
        },
        emphasis: { focus: 'series', scale: 1.3 }
      };
    }
  
    // ===== 5. 渲染 =====
    function renderChart(key) {
      if (!chart) return;
      var d = CONTESTS[key];
      if (!d) return;
      chart.setOption({
        backgroundColor: 'transparent',
        tooltip: {
          trigger: 'axis',
          // tooltip 列表顺序：series 声明反序 → 一等、二等、三等
          order: 'seriesDesc',
          axisPointer: { type: 'line', lineStyle: { color: 'rgba(128,128,128,0.3)' } }
        },
        legend: {
          top: 0,
          // 图例顺序：显式指定，好奖项在前
          data: ['一等奖', '二等奖', '三等奖'],
          icon: 'roundRect',
          itemWidth: 14,
          itemHeight: 4,
          textStyle: { color: '#888', fontSize: 13 }
        },
        grid: { left: 50, right: 30, top: 50, bottom: 40 },
        xAxis: {
          type: 'category',
          data: d.years,
          boundaryGap: false,
          axisLine: { lineStyle: { color: 'rgba(128,128,128,0.25)' } },
          axisLabel: { color: '#888' }
        },
        yAxis: {
          type: 'value',
          name: '人数',
          minInterval: 1,
          nameTextStyle: { color: '#888' },
          axisLabel: { color: '#888' },
          splitLine: { lineStyle: { color: 'rgba(128,128,128,0.12)' } }
        },
        // 渲染顺序：先三等（底层）→ 再二等（中层）→ 最后一等（顶层）
        // ECharts 中后声明的 series 绘制在上层，重合时好奖项盖住差奖项
        series: [
          makeSeries('三等奖', d.third,  BRONZE),
          makeSeries('二等奖', d.second, SILVER),
          makeSeries('一等奖', d.first,  GOLD)
        ]
      }, { replaceMerge: ['series'] });
    }
  
    // ===== 6. 初始化入口 =====
    function init() {
      // 先绑定 tab：不依赖 echarts，保证按钮永远有响应
      document.querySelectorAll('.contest-tab').forEach(function (btn) {
        btn.addEventListener('click', function () {
          document.querySelectorAll('.contest-tab').forEach(function (b) {
            b.classList.remove('active');
          });
          btn.classList.add('active');
          renderChart(btn.dataset.contest);
        });
      });
  
      // 再加载 ECharts 并初始化图表
      loadECharts().then(function () {
        chart = echarts.init(document.getElementById('award-chart'));
        renderChart('CSP-J');
        window.addEventListener('resize', function () {
          if (chart) chart.resize();
        });
      }).catch(function (err) {
        console.error(err);
        var box = document.getElementById('chart-error');
        if (box) {
          box.style.display = 'block';
          box.textContent = '图表加载失败：' + err.message;
        }
      });
    }
  
    // ===== 7. DOM 就绪后执行 =====
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', init);
    } else {
      init();
    }
  })();