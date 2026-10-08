# IV：Stata 构建与内生性检验

IV 构建以 Stata 为主线；内生性检验分别保留 Stata 与 MATLAB 实现。

## 目录

```text
iv_construction/          IV 构建（仅 Stata）
  national_g.do          全国队列人口比 g
  run_iv.do              城市 IV 构建
endogeneity/
  stata/                 Stata 数据准备与内生性检验
  matlab/                MATLAB 内生性检验与测试
  DATA_MATCH.md          数据口径核对
```

- [IV 构建说明](iv_construction/README.md)：手动导入 Excel 后使用 Stata；含当前脚本的输入要求。
- [内生性检验说明](endogeneity/README.md)：模型、数据、检验解释和运行方法。
- [Stata 内生性代码](endogeneity/stata/)。
- [MATLAB 内生性代码](endogeneity/matlab/)：保留 eng-sample.xls 原始变量名和中文摘要。

先构建全国 g 和城市 IV，再进行内生性检验。代码目录与数据工作目录可以不同；调用脚本时使用代码完整路径，数据和输出仍按各脚本原有路径处理。

## 分支与本次整理

以默认分支 `main` 为后续维护主线。`stata-iv` 同步到本次整理版本，两个分支的历史均保留。

本次将原 `stata-iv` 的最新 Stata IV 脚本移至 `iv_construction/`，将原 `main` 的内生性代码按语言分目录。所有保留的代码内容不变，仅更新说明与位置；根目录的 MATLAB IV 构建代码已移除。已有数据、日志和结果文件保留在 `endogeneity/` 原位置。

本次验证为文件内容与目录结构核对，没有重新运行估计；历史运行记录见模块说明。
