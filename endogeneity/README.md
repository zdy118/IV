# 长差分 IV 与内生性检验（2026-10-03）

本模块使用新的队列推进 IV，替代论文4.3.3旧版历史生育率IV的实现。它只对应“老龄化→TFP”，不能用于论文4.2的“TFP→人口流动”方程。所有模型均为2010—2020年每市一行的横截面。

## 数据依据

先读 [DATA_MATCH.md](DATA_MATCH.md)。按论文表2-1核对，入口采用 `最全数据面板.dta` 的2004—2022年记录。`新时不变实际tfp`、`新时不变前沿tfp` **已经是ln(TFP)**，直接计算2020减2010，不再取对数。相同两列也存在于另两个版本中，已逐城市年份核对完全一致。

IV表来自已经完成的 `iv_2010_2020.xlsx`，必须包含 `city_id city_name OR2010 OR2020 predOR2010 predOR2020 D Z`。代码重新核对D、Z与各比率的恒等关系，不沿用旧历史生育率IV。全国g、2000年基期及85+尾组规则保持不变。

## Stata：两步运行

将工作目录设到一个可写目录，将IV结果Excel放在这里。以下脚本全部完整运行，避免分块运行造成local作用域丢失。原始面板不会被覆盖；本模块生成的同名结果会覆盖。

1. 手动打开 `最全数据面板.dta`，运行 `prepare_endogeneity.do`。
2. 运行 `test_endogeneity.do`。

无需安装ivreg2、ivreghdfe或其他扩展。使用Stata18原生命令。数据准备使用实体 `panel_long_difference.dta`，不依赖跨do-file的临时文件宏。缺失、重复、未匹配均保留审计记录；最终样本282市。

## MATLAB

将本目录加入路径，在同一个数据工作目录运行：

```matlab
addpath('你的仓库/endogeneity');
run_endogeneity('endogeneity_sample.csv','matlab_endogeneity_results');
% 程序自检（不使用私人数据）：
test_endogeneity;
% 两种语言都运行后比较：
compare_stata_results('endogeneity_results.csv', ...
    'matlab_endogeneity_results/endogeneity_results.csv');
```

MATLAB R2020b+；估计部分只用基础矩阵运算和betainc/betaincinv，无额外工具箱。MATLAB不直接读取用户的DTA：先由同目录 `prepare_endogeneity.do` 导出统一CSV，再独立计算OLS、2SLS、协方差和全部检验。也可手工准备同结构CSV，列定义见下方。它不会读取Stata估计结果作为自己的估计输入。

`endogeneity_sample.csv`每市一行，数值列至少包括：city_id、province、D、Z、Y_actual、Y_frontier、Y_actual_w、Y_frontier_w、ln_pop0、edu0、ln_budget0、age0、age0_sq、Y_pre、ln_pop_pre、edu_pre、ln_budget_pre。四个Y分别为原始/缩尾后的实际/前沿**对数TFP长差分**；province为六位城市代码前两位。省份、年龄平方、重复键和非有限值均检查。

## 估计设定（不是旧面板回归的机械复刻）

- 内生解释变量：`D=ln(OR2020)-ln(OR2010)`；`OR=60+/20+`，不是60+/总人口或百分点变化。
- 排除工具：`Z=ln(predOR2020)-ln(predOR2010)`；两期预测都从2000年出发。
- 因变量：`Y=lnTFP2020-lnTFP2010`。系数是长差分弹性，不能直接代替论文旧年度百分点系数，也不能原样用于退休政策模拟。
- baseline：2009年的ln(常住人口万人)、平均受教育年限、ln(人均财政支出)。这些是本次预先选定的事前控制，不由回归显著性筛选。
- province：在baseline基础上加入省份固定效应。
- age：在baseline基础上加入2009年平均劳动年龄及其平方，仅作为额外敏感性设定；不将研究期内年龄变化当作已证明外生的控制。
- 三种设定各报告HC1异方差稳健和按省CR1聚类标准误。省份按行政代码而非有录入错误的文字省名确定。一个城市一行，不加城市固定效应，也不重复加入年份固定效应。
- 原始实际TFP为主要结果；前沿TFP、两种TFP的1%/99%缩尾为敏感性结果，共4×3×2=24组。缩尾在2004—2022的5358条lnTFP记录上按Stata分位点实施，然后相减；不重新缩尾D、Z或长差分。这里仅考察TFP缩尾，不声称完全复刻旧论文全部变量缩尾设定。
- 四类结果采用同一完整样本，便于比较。估计不加人口权重。所有外生控制同时进入第一阶段和结构方程。

## 每项检验回答什么

1. 第一阶段 `D~Z+X`：报告Z系数、标准误、仅针对排除工具Z的Wald F及p值、partial R²。它不是整条回归总体F，也不冒充Kleibergen–Paap或Montiel Olea–Pflueger统计量。不能把稳健/聚类F机械对比Stock–Yogo同方差临界值16.38，不能只凭F>10宣布IV有效。
2. OLS与原生2SLS：同一样本、同一控制集；Stata使用 `ivregress 2sls, small`，MATLAB使用结构残差构造HC1/CR1协方差，避免直接回归拟合D导致错误标准误。
3. 内生性检验：Stata `estat endogenous` 的稳健回归型F；MATLAB估计第一阶段残差加入结构回归后的相同检验。H0是D外生，**不是Z外生**。拒绝意味着在工具有效等假设下有内生性证据；不拒绝不等于证明D外生，也不据此自动选择OLS。
4. Anderson–Rubin：检验H0:beta=0，并通过对 `Y-beta*D~Z+X` 的同一稳健F检验求反演95%置信集合。单工具情况下形成二次不等式 `A*beta²+B*beta+C<=0`，输出完整区间、两段无界集合、全实数或空集；不靠有限网格截断。它对弱识别稳健，但仍需工具外生、控制正确、相应独立/聚类渐近条件。
5. 事前趋势：回归2004—2009年TFP变化对Z，控制2004年特征，按省聚类。仅为历史相关性诊断；由于2000年龄结构也可能影响此前老龄化，不能把它当作严格的无效应安慰剂，也不能把不显著当作排除性证明。
6. 当前恰好识别（1个Z、1个D），不运行Sargan/Hansen过度识别检验、不输出“通过过识别”。

## 输出

- `endogeneity_results.csv/.dta`：24组结果。OLS/IV系数与标准误、第一阶段F、partial R²、内生性F/p、AR零效应F/p、二次式系数和AR95集合。
- `pretrend_diagnostic.csv`：事前趋势的样本、聚类数、Z系数、标准误、F、p。
- `endogeneity_sample.csv/.dta`：共用估计样本。
- `merge_audit.csv`、`sample_audit.csv`、`province_label_audit.csv`：合并、缺失与省名核对。
- `endogeneity_stata.log`：完整回归和检验输出。
- MATLAB结果写入调用时指定的独立目录，避免覆盖Stata结果。

## 识别与解释边界

历史年龄结构的预定性不等于排除性。持久产业结构、教育、迁移预期、医疗和共同冲击可能同时影响Z和TFP。当前入口中没有可直接确认的2000年行业份额控制，代码没有捏造这些变量；如补齐，应事先指定并加入两阶段，再报告结果。2009年控制是时期前的观测，不自动保证不存在预期效应；插值变量还应核实其信息来源。

全国g按已实现的全国队列变化计算，包含死亡、跨境迁移、登记差异；未做剔除本市的g。它在本模块中作为已给定的共同推进因子，未传播人口测量误差/TFP估计误差。省级聚类允许省内相关，但不保证处理了跨省空间相关或所有共同队列冲击。仅30个省级簇，聚类渐近推断仍有有限样本局限。AR解决弱识别问题，不修复无效工具。

## 来源与验证


- [Stata官方IV后估计手册](https://www.stata.com/manuals/rivregresspostestimation.pdf)：稳健内生性检验与第一阶段统计量。
- [Stata官方2SLS说明](https://www.stata.com/support/faqs/statistics/instrumental-variables-regression/)：两阶段工具和标准误。
- [Hendy原文](https://www.rba.gov.au/publications/rdp/2025/2025-08/full.html)：队列推进设计；本项目不沿用其省级样本的工具强度。
