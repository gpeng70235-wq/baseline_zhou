# Run and Reproduce

要求 MATLAB R2024b 或兼容版本。当前验证环境入口为 `D:\software\MATLAB R2024b\bin\matlab.exe`。不要添加任何上游到 MATLAB path。

```powershell
Set-Location 'C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_design_iter01'
& 'D:\software\MATLAB R2024b\bin\matlab.exe' -batch "r=run_dual_timescale_design('all'); disp(r)"
```

模式可单独运行：`inventory` 读取前后 hash 表；`literature` 验证 8 个 canonical PDF 路径；`timing` 检查冻结 timing source copies；`design` 运行合成参考计算并写 MATLAB timing；`audit` 运行十个测试文件；无参数等价于 all。

这些命令不运行闭环和 24 工况。若要重新生成后置 SHA256，应从 `audit/SOURCE_PROJECTS.csv` 逐文件计算，并与 before 以 `project_id+relative_path` 比较；不能通过修改上游来“修复”差异。

预期结果：8/8 PDF；timing evidence complete；controller_connected=false；tests 全通过；upstream changed=0。任何失败先查 `docs/KNOWN_LIMITATIONS.md`，不得自动创建 prototype。
