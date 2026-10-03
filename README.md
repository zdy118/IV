# 人口老龄化 IV：Stata 简化版

本分支 `stata-iv` 使用手动导入 Excel 的工作方式，只保留两个计算脚本：

1. 导入全国表后，运行 [stata/national_g.do](stata/national_g.do)，计算全国队列变化率 g。
2. 导入城市表后，运行 [stata/run_iv.do](stata/run_iv.do)，计算实际老龄化变化 D 和工具变量 Z。

**导入范围及操作步骤见 [Stata说明](stata/README.md)。** 无须设置路径宏或加载自定义程序。结果保存为当前工作目录中的 DTA 和 Excel 文件。

两个预测都从2000年出发，保留85+尾组处理。2026-10-03在Stata/MP 18使用真实数据运行成功，共287市；结果与原版最大差异7.8e-16。

原MATLAB代码保留，[MATLAB说明及全国数据来源](MATLAB_README.md)仍可查阅。
