# Stata版人口老龄化IV构建

本分支从 MATLAB 版 main 创建，Stata代码位于 `stata/`。需要 Stata 16或更新版本，无须安装外部命令。Excel原始数据仅在本地读取。

## 运行

1. 下载 `stata-iv` 分支，令 Stata 当前目录为仓库根目录。
2. 在 `stata/run_iv.do` 顶部修改 `data` 路径。默认读取 `iv-essential data2.xlsx` 和 `total_national.xlsx`。
3. 运行 `do stata/test_iv.do` 验证模拟数据，再运行 `do stata/run_iv.do`。

代码会清空当前内存数据，请先保存正在编辑的数据。输出写入仓库 `results/stata_日期时间/`，每次运行新建目录。

## 方法

`iv_lib.do` 中 `iv_g` 独立计算全国g；`iv_build` 使用同一份g预测城市人口。普通组：`g(b,tau)=全国(2000+tau)年(b+tau)组人口/全国2000年b组人口`，tau为10或20。两期都以2000年为基期，g不减1、不年化、不截断至1。

本版本统一五岁组0—4至80—84及85+。目标2010年85+对应基期75+，目标2020年85+对应基期65+，分别合并基期尾部后计算g。全国g共30行；尾组合并是一项近似，需保留其内部年龄构成可比的假设。

`OR = 60岁及以上人口 / 20岁及以上人口`；`D=ln(OR2020)-ln(OR2010)`；`Z=ln(predOR2020)-ln(predOR2010)`。人口求和和比率采用double精度。

导入器核对年龄表头、排除明确标记的合计行、合并0岁和1—4岁，检查各市三期年龄组完整且唯一。缺失不填零，文本数值不强制转为缺失。参考人口与样本城市合计完全相等时停止；明显人口异常保存诊断后停止。

## 输出

- `national_cohort_rates.dta/.csv`：基期、目标年、年龄组、开放组标记、全国分子分母和g。
- `iv_2010_2020.dta/.csv`：城市名称、实际及预测OR、D、Z和人数汇总。
- `cohort_audit.dta/.csv`：每市各预测队列的基期人口、g与预测人数。
- 标准化城市/全国DTA、诊断CSV和运行日志。

单独计算g：先加载 `do stata/iv_lib.do`，然后运行 `iv_g using "national_age.dta", saving("national_cohort_rates.dta")`。标准化全国表必须有数值列year、age_start、population。

本代码完成数据处理与IV构建，不自动进行TFP回归。之后需按city_id合并TFP长差分及事前控制变量，另行进行2SLS和第一阶段/弱工具变量检验。全国数据的来源与登记口径限制见根目录 `MATLAB_README.md`；三期均用全国普查登记明细表，不按公报总人数重标年龄结构。

2026-10-02在Stata/MP 18运行模拟测试与真实数据成功。实际输出287市、30行g、8,610行队列明细；独立数值复核误差小于1e-12。数据和结果不上传GitHub。
