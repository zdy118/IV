# 人口老龄化 IV：Stata 简化版

## 新增：2010—2020年内生性检验

见 [endogeneity/README.md](endogeneity/README.md)。新增与当前队列推进IV一致的OLS、2SLS、稳健内生性检验、第一阶段诊断和Anderson–Rubin置信集合，并提供Stata和MATLAB实现。数据准备与估计分开，原有IV构建流程保留。

TFP已按论文表2-1核对，使用已取对数的实际/前沿TFP，详见 [数据匹配记录](endogeneity/DATA_MATCH.md)。Stata18已实际运行282市、24组设定并独立数值复核；MATLAB因本机启动错误尚未实际运行，不能将其测试文件的存在视为测试通过。原始数据和逐城市结果不上传。

本分支 `stata-iv` 使用手动导入 Excel 的工作方式，IV构建部分使用两个计算脚本：

1. 导入全国表后，运行 [stata/national_g.do](stata/national_g.do)，计算全国队列变化率 g。
2. 导入城市表后，运行 [stata/run_iv.do](stata/run_iv.do)，计算实际老龄化变化 D 和工具变量 Z。

**导入范围及操作步骤见 [Stata说明](stata/README.md)。** 无须设置路径宏或加载自定义程序。结果保存为当前工作目录中的 DTA 和 Excel 文件。

两个预测都从2000年出发，保留85+尾组处理。2026-10-03在Stata/MP 18使用真实数据运行成功，共287市；结果与原版最大差异7.8e-16。

原MATLAB代码保留，[MATLAB说明及全国数据来源](MATLAB_README.md)仍可查阅。
