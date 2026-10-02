# Stata版人口老龄化IV构建

本分支 `stata-iv` 提供 Stata 实现：读取2000、2010、2020年城市与全国年龄人口，计算全国队列变化率g，预测城市老龄化，构造2010—2020年长差分IV。

## 开始运行

需要 Stata 16+，无需外部扩展。下载本分支后，将当前目录设为仓库根目录，在 `stata/run_iv.do` 顶部设置数据路径，然后运行：

```stata
do stata/test_iv.do
do stata/run_iv.do
```

代码会清空内存数据，请先保存正在编辑的数据。输入为 `iv-essential data2.xlsx` 和官方全国表 `total_national.xlsx`。结果存放在 `results/stata_日期时间/`，包括城市IV、全国g、队列核对表及诊断日志。

- [运行入口](stata/run_iv.do)
- [Excel导入](stata/import_census.do)
- [全国g与IV计算](stata/iv_lib.do)
- [详细说明](stata/README.md)
- [原MATLAB说明及官方数据来源](MATLAB_README.md)

## 定义与验证

OR为60岁及以上人口占20岁及以上人口的比例。两个预测均从2000年出发；D是实际OR的2010—2020年对数变化，Z是预测OR的同期对数变化。85+尾组按预测跨度合并基期人口；g不截断至1。

2026-10-02已在本机Stata/MP 18中通过模拟测试，并完成真实数据流程：287个城市、30行全国g、8,610行队列核对记录。独立读取Excel并重新计算，与Stata输出的OR、预测OR和Z核对一致，误差小于1e-12。这验证计算实现，不证明IV的相关性、排除性或行政区划口径一致性。

本分支完成IV构建，不包含TFP回归。原MATLAB文件保留供对照；main分支保持MATLAB版本。原始城市数据与运行结果不上传仓库。
