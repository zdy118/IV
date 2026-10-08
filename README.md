# IV：Stata 构建与内生性检验


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
