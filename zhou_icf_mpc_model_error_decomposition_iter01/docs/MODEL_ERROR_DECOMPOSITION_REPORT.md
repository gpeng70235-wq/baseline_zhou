# Model Error Decomposition Report

## 摘要

实际分析 `24` 个场景、`24153` 个样本。正式主域排除预先标记的 stress test；结论为 **C — F and alpha jointly dominate**。

前序 sequence 项已是浮点量级（sequence/total `1.02737154281e-13`），因此本报告只分解 F、alpha 与 P3b→P4→P5 的冻结/离散链。

## 全量预测器表现

口径：**REPRODUCTION_ALL**

| Predictor | Causality | valid n | vector RMS (A) | peak (A) | false-safe | false-alarm | max FS run | top-1 flip vs P0 | mode flip vs P0 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| P0 | causal_original | 24153 | 0.0462765806219 | 0.57171231501 | 3.059661% | 0.000000% | 11 | 0.000000% | 0.000000% |
| P1 | causal_original | 24153 | 0.313096475601 | 1.07672867773 | 1.999752% | 16.585931% | 11 | 9.410839% | 5.779820% |
| P2a | causal_previous_period_oracle | 24129 | 0.0639743506626 | 0.527630896212 | 1.877409% | 1.504414% | 11 | 1.498779% | 0.770091% |
| P2b | offline_physical_parameter_oracle | 24153 | 0.31213763231 | 0.932835107894 | 1.055769% | 17.335321% | 10 | 14.375026% | 6.425703% |
| P2c | noncausal_future_endpoint_oracle | 24153 | 0.0451051288638 | 0.288581654687 | 1.622987% | 1.316607% | 10 | 1.606426% | 1.304186% |
| P3a | causal_previous_period_oracle | 24129 | 0.0193138460033 | 0.269943850411 | 0.915910% | 0.327407% | 11 | 0.997806% | 0.948122% |
| P3b | offline_physical_parameter_oracle | 24153 | 0.0193622378884 | 0.193922473834 | 0.807353% | 0.794932% | 10 | 1.018507% | 0.948122% |
| P3c | noncausal_future_endpoint_oracle | 24153 | 0.00745979125119 | 0.0949396561515 | 0.679005% | 0.298100% | 10 | 1.088892% | 0.919140% |
| P4 | offline_physical_parameter_oracle | 24153 | 0.00744528837188 | 0.0942986359173 | 0.679005% | 0.298100% | 10 | 1.088892% | 0.919140% |
| P5 | offline_plant_replay_oracle | 24153 | 0 | 0 | 0.000000% | 0.000000% | 0 | 1.134435% | 0.939842% |

## 工程主域预测器表现

口径：**ENGINEERING_PRIMARY**

| Predictor | Causality | valid n | vector RMS (A) | peak (A) | false-safe | false-alarm | max FS run | top-1 flip vs P0 | mode flip vs P0 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| P0 | causal_original | 23699 | 0.0456593555986 | 0.57171231501 | 3.029664% | 0.000000% | 11 | 0.000000% | 0.000000% |
| P1 | causal_original | 23699 | 0.315926534118 | 1.07672867773 | 1.949449% | 16.903667% | 11 | 9.591122% | 5.890544% |
| P2a | causal_previous_period_oracle | 23677 | 0.0643892364429 | 0.527630896212 | 1.833002% | 1.533133% | 11 | 1.519051% | 0.780624% |
| P2b | offline_physical_parameter_oracle | 23699 | 0.315084355313 | 0.932835107894 | 1.033799% | 17.667412% | 10 | 14.641968% | 6.544580% |
| P2c | noncausal_future_endpoint_oracle | 23699 | 0.0454940202474 | 0.288581654687 | 1.611882% | 1.341829% | 10 | 1.628761% | 1.324950% |
| P3a | causal_previous_period_oracle | 23677 | 0.018848633464 | 0.269943850411 | 0.853149% | 0.333657% | 11 | 1.008481% | 0.962066% |
| P3b | offline_physical_parameter_oracle | 23699 | 0.0190753798752 | 0.193922473834 | 0.780624% | 0.810161% | 10 | 1.029579% | 0.962066% |
| P3c | noncausal_future_endpoint_oracle | 23699 | 0.00727829135084 | 0.0933398900547 | 0.649816% | 0.303810% | 10 | 1.101312% | 0.932529% |
| P4 | offline_physical_parameter_oracle | 23699 | 0.00726303284354 | 0.0928817907917 | 0.649816% | 0.303810% | 10 | 1.101312% | 0.932529% |
| P5 | offline_plant_replay_oracle | 23699 | 0 | 0 | 0.000000% | 0.000000% | 0 | 1.147728% | 0.953627% |

## 主域 MSE 归因

| Predictor | vector MSE (A^2) |
|---|---:|
| P0 | 0.00208551411811 |
| P1 | 0.0998654102013 |
| P2a | 0.0041459737697 |
| P2b | 0.0993395517012 |
| P2c | 0.0020700529137 |
| P3a | 0.00035527098346 |
| P3b | 0.000364123811193 |
| P3c | 5.29337822385e-05 |
| P4 | 5.27100058389e-05 |
| P5 | 0 |

| Registered delta | A^2 |
|---|---:|
| F causal: P0-P2a | -0.00206045965159 |
| F instant: P0-P2b | -0.0972540375831 |
| alpha: P0-P1 | -0.0977798960832 |
| joint instant: P0-P3b | 0.00172139030691 |
| F-alpha interaction | 0.196755323973 |
| two-period F freezing: P3b-P4 | 0.000311413805354 |
| discretization/segments: P4-P5 | 5.27100058389e-05 |
| structure total: P3b-P5 | 0.000364123811193 |
| remaining oracle gap: P5 | 0 |

F、alpha、结构对 P0→P5 explained MSE 的有符号份额为 `53.877574%`、`28.662760%`、`17.459667%`。这是替换实验结果；相关性表只帮助定位工况，不承担因果结论。

## 约束混淆（工程主域）

| Predictor | n | false-safe count/rate | false-alarm count/rate | violation recall | safe specificity |
|---|---:|---:|---:|---:|---:|
| P0 | 23699 | 718 / 3.029664% | 0 / 0.000000% | 2.841678% | 100.000000% |
| P1 | 23699 | 462 / 1.949449% | 4006 / 16.903667% | 37.483085% | 82.552265% |
| P2a | 23677 | 434 / 1.833002% | 363 / 1.533133% | 41.112619% | 98.417611% |
| P2b | 23699 | 245 / 1.033799% | 4187 / 17.667412% | 66.847091% | 81.763937% |
| P2c | 23699 | 382 / 1.611882% | 318 / 1.341829% | 48.308525% | 98.614983% |
| P3a | 23677 | 202 / 0.853149% | 79 / 0.333657% | 72.591588% | 99.655623% |
| P3b | 23699 | 185 / 0.780624% | 192 / 0.810161% | 74.966171% | 99.163763% |
| P3c | 23699 | 154 / 0.649816% | 72 / 0.303810% | 79.161028% | 99.686411% |
| P4 | 23699 | 154 / 0.649816% | 72 / 0.303810% | 79.161028% | 99.686411% |
| P5 | 23699 | 0 / 0.000000% | 0 / 0.000000% | 100.000000% | 100.000000% |

## 候选诊断（次级证据）

| Predictor | valid n | top-1 flip | mode flip | P5 agreement | top-1 recovered/eligible | mode recovered/eligible | new top-1 errors |
|---|---:|---:|---:|---:|---:|---:|---:|
| P0 | 23699 | 0.000000% | 0.000000% | 98.852272% | 0 / 272 | 0 / 226 | 0 |
| P1 | 23699 | 9.591122% | 5.890544% | 90.117726% | 83 / 272 | 70 / 226 | 2153 |
| P2a | 23677 | 1.520463% | 0.781349% | 97.609494% | 33 / 272 | 21 / 226 | 327 |
| P2b | 23699 | 14.641968% | 6.544580% | 85.298958% | 128 / 272 | 112 / 226 | 3340 |
| P2c | 23699 | 1.628761% | 1.324950% | N/A | 0 / 0 | 0 / 0 | 0 |
| P3a | 23677 | 1.009418% | 0.962960% | 99.607214% | 209 / 272 | 198 / 226 | 30 |
| P3b | 23699 | 1.029579% | 0.962066% | 99.594920% | 210 / 272 | 194 / 226 | 34 |
| P3c | 23699 | 1.101312% | 0.932529% | N/A | 0 / 0 | 0 / 0 | 0 |
| P4 | 23699 | 1.101312% | 0.932529% | 99.801679% | 243 / 272 | 203 / 226 | 18 |
| P5 | 23699 | 1.147728% | 0.953627% | 100.000000% | 272 / 272 | 226 / 226 | 0 |

候选 bank 明确不是原生 Zhou candidates；P2c/P3c 的 ranking_valid=false。候选恢复只用于判断 RMSE 改善是否跨越诊断边界，不能单独决定 A--F。

## 残差关联（描述性）

| Axis | Variable | n | Pearson r | Spearman r | best |xcorr| | lag |
|---|---|---:|---:|---:|---:|---:|
| d | F_time_increment_d | 24129 | 0.563833573792 | 0.13903818679 | 0.94849857841 | -2 |
| d | reference_rate_A_s | 24153 | 0.31943477655 | 0.334519021904 | N/A | N/A |
| d | F_time_increment_q | 24129 | -0.237923373881 | -0.211498367432 | 0.237923373881 | 0 |
| q | F_time_increment_q | 24129 | -0.186294923573 | 0.0373824416026 | 0.893689780477 | -2 |
| d | electrical_angle | 24153 | -0.184079126915 | -0.152240400187 | N/A | N/A |
| q | F_time_increment_d | 24129 | -0.145216710467 | -0.157085978276 | 0.219343441863 | -5 |
| d | iq | 24153 | -0.127457899203 | -0.0871623992893 | N/A | N/A |
| d | voltage_utilization | 24153 | 0.125122959926 | -0.051716872356 | N/A | N/A |
| d | sin_electrical_angle | 24153 | 0.124810057726 | 0.0628165145907 | N/A | N/A |
| d | iq_ref | 24153 | -0.109525655527 | -0.0945335541669 | N/A | N/A |
| d | F_estimation_error_d | 24153 | -0.108210278117 | -0.270854705784 | 0.11067207291 | -1 |
| d | speed_rpm | 24153 | 0.0946988195708 | -0.0199543304422 | N/A | N/A |

上述相关性不得解释为因果。F 与 alpha 的 causal attribution 来自预测器替换，并受 gauge 约束。

## 相干频谱

| Case | Axis | cycles | n | 1x RMS | 6x RMS | 12x RMS | dominant order/amplitude |
|---|---|---:|---:|---:|---:|---:|---:|
| C05_negative_id | d | 3 | 500 | 2.2650605677e-08 | 0.00611185244243 | 0.00253895401178 | 6 / 0.00611185244243 |
| C05_negative_id | q | 3 | 500 | 3.64389959153e-08 | 0.00541449035203 | 0.00414517622561 | 6 / 0.00541449035203 |
| C06_low_bus_43p2V | d | 3 | 500 | 1.77561953881e-08 | 0.00551991621704 | 0.00183444719872 | 6 / 0.00551991621704 |
| C06_low_bus_43p2V | q | 3 | 500 | 4.14335465907e-08 | 0.00514218277649 | 0.00243142560476 | 6 / 0.00514218277649 |
| C09_S2_boundary | d | 5 | 500 | 1.1013634798e-06 | 0.0113346130691 | 0.0105743012687 | 6 / 0.0113346130691 |
| C09_S2_boundary | q | 5 | 500 | 9.10419483574e-07 | 0.00738790853329 | 0.00753261348621 | 12 / 0.00753261348621 |
| D02_id_step | d | 3 | 500 | 5.77351576632e-05 | 0.00798452112022 | 0.00243361725593 | 6 / 0.00798452112022 |
| D02_id_step | q | 3 | 500 | 5.1370502011e-05 | 0.00102712123089 | 0.0031603408487 | 12 / 0.0031603408487 |
| D03_id_iq_step | d | 3 | 500 | 3.07660787381e-08 | 0.00602708479817 | 0.00194525345546 | 6 / 0.00602708479817 |
| D03_id_iq_step | q | 3 | 500 | 2.77195758541e-08 | 0.0050315880787 | 0.00285640819834 | 6 / 0.0050315880787 |
| D04_torque_ramp | d | 4 | 500 | 0.000317172137142 | 0.00973063822719 | 0.00757592923621 | 6 / 0.00973063822719 |
| D04_torque_ramp | q | 4 | 500 | 0.000195453963493 | 0.006821811049 | 0.00609913364421 | 6 / 0.006821811049 |
| P01_Ld_minus10 | d | 3 | 500 | 1.26625833382e-08 | 0.00674935809299 | 0.00585311717921 | 18 / 0.00823396901322 |
| P01_Ld_minus10 | q | 3 | 500 | 1.26571707276e-08 | 0.00468465513678 | 0.00256777652399 | 6 / 0.00468465513678 |
| P02_Ld_plus10 | d | 3 | 500 | 9.32531647147e-08 | 0.00721156996864 | 0.00326095700386 | 18 / 0.00900113811811 |
| P02_Ld_plus10 | q | 3 | 500 | 7.31022847923e-08 | 0.00551548032931 | 0.00319825035395 | 6 / 0.00551548032931 |
| P03_Lq_minus10 | d | 3 | 500 | 6.17253436431e-08 | 0.00502039498265 | 0.00305093700448 | 6 / 0.00502039498265 |
| P03_Lq_minus10 | q | 3 | 500 | 5.75529939169e-08 | 0.00602634671461 | 0.00510042177187 | 24 / 0.00778425042022 |
| P04_Lq_plus10 | d | 3 | 500 | 8.46148078666e-08 | 0.00760319367807 | 0.00513758959947 | 6 / 0.00760319367807 |
| P04_Lq_plus10 | q | 3 | 500 | 6.63181131682e-08 | 0.00629293917378 | 0.00586086230417 | 18 / 0.0104822227256 |
| P05_cross_mismatch | d | 4 | 500 | 0.000377683285745 | 0.010831004082 | 0.0121627461519 | 12 / 0.0121627461519 |
| P05_cross_mismatch | q | 4 | 500 | 0.00016932884273 | 0.00881432584488 | 0.0123894952286 | 12 / 0.0123894952286 |
| P06_controller_high_L | d | 4 | 500 | 0.000260843786856 | 0.0104625715721 | 0.0138847037154 | 24 / 0.0398046078925 |
| P06_controller_high_L | q | 4 | 500 | 0.000206040599226 | 0.00910486537436 | 0.0105134411087 | 24 / 0.0289184873247 |
| P07_controller_low_L | d | 4 | 500 | 0.000614113825612 | 0.020088320017 | 0.0196845026904 | 6 / 0.020088320017 |
| P07_controller_low_L | q | 4 | 500 | 0.00037633976505 | 0.0152786551333 | 0.0175663866796 | 12 / 0.0175663866796 |
| P08_opposed_20pct | d | 4 | 500 | 0.00033089648002 | 0.0156542821198 | 0.0133396871384 | 18 / 0.0187833817033 |
| P08_opposed_20pct | q | 4 | 500 | 0.000352383718762 | 0.0154803307738 | 0.0182814921964 | 18 / 0.0432574691632 |

无效窗口保留在 `residual_spectrum.csv` 并说明原因；没有用短窗谱峰填补证据。

## 工况分类

| Case | Category | Range | rpm | id* | iq* | Vdc | samples | S2 | P0 FS | P5 max gap (A) | Notes |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| C01_nominal_100rpm_10A | core | normal | 100 | 0 | 10 | 48 | 1198 | 0 | 0.250417% | 0 |  |
| C02_light_100rpm_4A | core | normal | 100 | 0 | 4 | 48 | 1198 | 0 | 0.083472% | 0 |  |
| C03_light_200rpm_6A | core | normal | 200 | 0 | 6 | 48 | 1198 | 0 | 0.500835% | 0 |  |
| C04_high_200rpm_18A | core | normal | 200 | 0 | 18 | 48 | 1198 | 0 | 1.168614% | 0 |  |
| C05_negative_id | core | reasonable_extension | 300 | -4 | 15 | 48 | 1198 | 0 | 1.085142% | 0 |  |
| C06_low_bus_43p2V | core | reasonable_extension | 300 | 0 | 15 | 43.2 | 1198 | 0 | 1.836394% | 0 |  |
| C07_known_false_safe | core | normal | 500 | 0 | 20 | 48 | 29 | 7 | 65.517241% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |
| C08_S2_nontrigger | core | normal | 100 | 0 | 10 | 48 | 1198 | 0 | 0.333890% | 0 |  |
| C09_S2_boundary | core | normal | 500 | 0 | 20 | 48 | 1198 | 1 | 2.337229% | 0 |  |
| D01_iq_step | dynamic | normal | 300 | 0 | 18 | 48 | 451 | 0 | 3.325942% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |
| D02_id_step | dynamic | reasonable_extension | 300 | -5 | 0 | 48 | 1198 | 0 | 1.752922% | 0 |  |
| D03_id_iq_step | dynamic | reasonable_extension | 300 | -4 | 16 | 48 | 1198 | 0 | 2.671119% | 0 |  |
| D04_torque_ramp | dynamic | normal | 400 | 0 | 18 | 48 | 1198 | 0 | 3.923205% | 0 | ; torque reference is mapped from dq current, not an independent mechanical outer loop |
| D05_torque_step | dynamic | normal | 400 | 0 | 18 | 48 | 457 | 0 | 6.564551% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum; torque reference is mapped from dq current, not an independent mechanical outer loop |
| P01_Ld_minus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 5.425710% | 0 |  |
| P02_Ld_plus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 0.918197% | 0 |  |
| P03_Lq_minus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 6.761269% | 0 |  |
| P04_Lq_plus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 2.671119% | 0 |  |
| P05_cross_mismatch | parameter | reasonable_extension | 400 | 0 | 18 | 48 | 1198 | 0 | 6.260434% | 0 |  |
| P06_controller_high_L | parameter | reasonable_extension | 400 | 0 | 18 | 48 | 1198 | 0 | 7.595993% | 0 |  |
| P07_controller_low_L | parameter | reasonable_extension | 400 | 0 | 18 | 48 | 1198 | 0 | 1.669449% | 0 |  |
| P08_opposed_20pct | parameter | reasonable_extension | 400 | -3 | 17 | 48 | 1198 | 0 | 7.345576% | 0 |  |
| B01_500rpm_20A_48V_fast | boundary | stress_test | 500 | 0 | 20 | 48 | 3 | 2 | 0.000000% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |
| B02_500rpm_negid_48V | boundary | stress_test | 500 | -4 | 19.5959179423 | 48 | 451 | 0 | 4.656319% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |

## 图表清单

| # | File | Generated | Message |
|---:|---|---:|---|
| 1 | [`01_predictors_vs_actual.png`](../results/figures/01_predictors_vs_actual.png) | PASS |  |
| 2 | [`02_residual_rms_by_predictor.png`](../results/figures/02_residual_rms_by_predictor.png) | PASS |  |
| 3 | [`03_false_safe_by_predictor.png`](../results/figures/03_false_safe_by_predictor.png) | PASS |  |
| 4 | [`04_F_replacement_time_domain.png`](../results/figures/04_F_replacement_time_domain.png) | PASS |  |
| 5 | [`05_alpha_replacement_time_domain.png`](../results/figures/05_alpha_replacement_time_domain.png) | PASS |  |
| 6 | [`06_P3_P4_P5_error_chain.png`](../results/figures/06_P3_P4_P5_error_chain.png) | PASS |  |
| 7 | [`07_candidate_top1_flip_matrix.png`](../results/figures/07_candidate_top1_flip_matrix.png) | PASS |  |
| 8 | [`08_candidate_mode_flip_matrix.png`](../results/figures/08_candidate_mode_flip_matrix.png) | PASS |  |
| 9 | [`09_residual_vs_delta_F.png`](../results/figures/09_residual_vs_delta_F.png) | PASS |  |
| 10 | [`10_residual_vs_alpha_error.png`](../results/figures/10_residual_vs_alpha_error.png) | PASS |  |
| 11 | [`11_residual_vs_state.png`](../results/figures/11_residual_vs_state.png) | PASS |  |
| 12 | [`12_residual_spectrum.png`](../results/figures/12_residual_spectrum.png) | PASS |  |
| 13 | [`13_S2_residual_comparison.png`](../results/figures/13_S2_residual_comparison.png) | PASS |  |
| 14 | [`14_parameter_over_under_asymmetry.png`](../results/figures/14_parameter_over_under_asymmetry.png) | PASS |  |
| 15 | [`15_case_error_source_share.png`](../results/figures/15_case_error_source_share.png) | PASS |  |

## 证据分级

- 可部署证据：只有 P0 基线本身和闭环真实轨迹；本工程没有部署新方法。
- 时间因果诊断：P2a/P3a（上一周期）以及公式层面的 P1，但仍含 oracle 参数/对象端点。
- 物理 oracle：P2b/P3b/P4，用真实对象参数，不是在线方案。
- 非因果上界：P2c/P3c。
- 理论重放下界：P5。
- 尚未验证推断：任何 ESO、预测型 F、在线 alpha、扩展仿射或高阶模型的实际闭环收益。
