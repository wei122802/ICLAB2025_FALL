 
****************************************
Report : resources
Design : CNN
Version: T-2022.03
Date   : Mon Oct  6 10:55:01 2025
****************************************


Resource Report for this hierarchy in file ../01_RTL/CNN.v
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| add_x_1        | DW01_inc       | width=8    | add_149 (CNN.v:149)        |
| add_x_3        | DW01_inc       | width=2    | add_154_S2 (CNN.v:154)     |
| lt_x_11        | DW_cmp         | width=8    | lt_268 (CNN.v:268)         |
| div_12         | DW_div_uns     | a_width=8  | div_269 (CNN.v:269)        |
|                |                | b_width=3  |                            |
| add_x_13       | DW01_inc       | width=9    | add_269 (CNN.v:269)        |
| rem_14         | DW_div_uns     | a_width=8  | rem_269 (CNN.v:269)        |
|                |                | b_width=3  |                            |
| add_x_15       | DW01_inc       | width=4    | add_269_2 (CNN.v:269)      |
| gte_x_53       | DW_cmp         | width=8    | gte_284 (CNN.v:284)        |
| lt_x_54        | DW_cmp         | width=8    | lt_284 (CNN.v:284)         |
| div_56         | DW_div_uns     | a_width=32 | div_285 (CNN.v:285)        |
|                |                | b_width=3  |                            |
| add_x_57       | DW01_inc       | width=32   | add_285 (CNN.v:285)        |
| rem_58         | DW_div_uns     | a_width=32 | rem_285 (CNN.v:285)        |
|                |                | b_width=3  |                            |
| add_x_59       | DW01_inc       | width=4    | add_285_2 (CNN.v:285)      |
| lt_x_109       | DW_cmp         | width=8    | lt_357 (CNN.v:357)         |
| lt_x_112       | DW_cmp         | width=8    | lt_391 (CNN.v:391)         |
| gt_x_113       | DW_cmp         | width=8    | gt_391 (CNN.v:391)         |
| gt_x_183       | DW_cmp         | width=8    | gt_702 (CNN.v:702)         |
| lt_x_184       | DW_cmp         | width=8    | lt_702 (CNN.v:702)         |
| gt_x_185       | DW_cmp         | width=8    | gt_710 (CNN.v:710)         |
| gt_x_186       | DW_cmp         | width=8    | gt_718 (CNN.v:718)         |
| lt_x_187       | DW_cmp         | width=8    | lt_718 (CNN.v:718)         |
| gt_x_188       | DW_cmp         | width=8    | gt_726 (CNN.v:726)         |
| div_190        | DW_div_uns     | a_width=32 | div_683 (CNN.v:683)        |
|                |                | b_width=3  |                            |
| rem_191        | DW_div_uns     | a_width=32 | rem_683 (CNN.v:683)        |
|                |                | b_width=3  |                            |
| div_193        | DW_div_uns     | a_width=32 | div_687 (CNN.v:687)        |
|                |                | b_width=3  |                            |
| rem_194        | DW_div_uns     | a_width=32 | rem_687 (CNN.v:687)        |
|                |                | b_width=3  |                            |
| add_x_216      | DW01_inc       | width=8    | add_880 (CNN.v:880)        |
| add_x_217      | DW01_inc       | width=8    | add_882 (CNN.v:882)        |
| add_x_218      | DW01_inc       | width=8    | add_884 (CNN.v:884)        |
| add_x_219      | DW01_inc       | width=8    | add_886 (CNN.v:886)        |
| add_x_220      | DW01_inc       | width=8    | add_888 (CNN.v:888)        |
| add_x_221      | DW01_inc       | width=8    | add_890 (CNN.v:890)        |
| add_x_222      | DW01_inc       | width=8    | add_892 (CNN.v:892)        |
| add_x_223      | DW01_inc       | width=8    | add_894 (CNN.v:894)        |
| gt_x_237       | DW_cmp         | width=8    | gt_902 (CNN.v:902)         |
| lt_x_238       | DW_cmp         | width=8    | lt_902 (CNN.v:902)         |
| gt_x_249       | DW_cmp         | width=8    | gt_971 (CNN.v:971)         |
| lt_x_250       | DW_cmp         | width=8    | lt_971 (CNN.v:971)         |
| gt_x_260       | DW_cmp         | width=8    | gt_1030 (CNN.v:1030)       |
| lt_x_261       | DW_cmp         | width=8    | lt_1030 (CNN.v:1030)       |
| gt_x_264       | DW_cmp         | width=8    | gt_1074 (CNN.v:1074)       |
| lt_x_265       | DW_cmp         | width=8    | lt_1074 (CNN.v:1074)       |
| mul_1          | DW_fp_mult     | sig_width=23 | mul_1 (CNN.v:576)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_2          | DW_fp_mult     | sig_width=23 | mul_2 (CNN.v:577)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_3          | DW_fp_mult     | sig_width=23 | mul_3 (CNN.v:578)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_4          | DW_fp_mult     | sig_width=23 | mul_4 (CNN.v:579)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_5          | DW_fp_mult     | sig_width=23 | mul_5 (CNN.v:580)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_6          | DW_fp_mult     | sig_width=23 | mul_6 (CNN.v:581)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_7          | DW_fp_mult     | sig_width=23 | mul_7 (CNN.v:582)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_8          | DW_fp_mult     | sig_width=23 | mul_8 (CNN.v:583)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| mul_9          | DW_fp_mult     | sig_width=23 | mul_9 (CNN.v:584)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| sum3_1         | DW_fp_sum3     | sig_width=23 | sum3_1 (CNN.v:587)       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
|                |                | arch_type=0 |                           |
| sum3_2         | DW_fp_sum3     | sig_width=23 | sum3_2 (CNN.v:588)       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
|                |                | arch_type=0 |                           |
| sum3_3         | DW_fp_sum3     | sig_width=23 | sum3_3 (CNN.v:589)       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
|                |                | arch_type=0 |                           |
| sum3_4         | DW_fp_sum3     | sig_width=23 | sum3_4 (CNN.v:591)       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
|                |                | arch_type=0 |                           |
| add_1          | DW_fp_add      | sig_width=23 | add_1 (CNN.v:746)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| exp_1          | DW_fp_exp      | sig_width=23 | exp_1 (CNN.v:904)        |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
|                |                | arch=2     |                            |
| add_mom        | DW_fp_add      | sig_width=23 | add_mom (CNN.v:930)      |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| add_son        | DW_fp_add      | sig_width=23 | add_son (CNN.v:931)      |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| recip_1        | DW_fp_recip    | sig_width=23 | recip_1 (CNN.v:975)      |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
|                |                | faithful_round=0 |                      |
| mult_1         | DW_fp_mult     | sig_width=23 | mult_1 (CNN.v:976)       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| selectmax      | DW_fp_sum4     | sig_width=23 | selectmax (CNN.v:1241)   |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
|                |                | arch_type=0 |                           |
| comparemax     | DW_fp_cmp      | sig_width=23 | comparemax (CNN.v:1242)  |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare8             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare8 (CNN.v:1367) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare7             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare7 (CNN.v:1365) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare6             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare6 (CNN.v:1363) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare5             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare5 (CNN.v:1362) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare4             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare4 (CNN.v:1360) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare3             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare3 (CNN.v:1359) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare2             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare2 (CNN.v:1358) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| Maxpooling/compare1             |            |                            |
|                | DW_fp_cmp      | sig_width=23 | Maxpooling/compare1 (CNN.v:1357) |
         |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
| lt_x_1166      | DW_cmp         | width=8    | lt_304 (CNN.v:304)         |
|                |                |            | lt_332 (CNN.v:332)         |
| gte_x_1167     | DW_cmp         | width=8    | gte_318 (CNN.v:318)        |
|                |                |            | gte_346 (CNN.v:346)        |
| lt_x_1168      | DW_cmp         | width=8    | lt_318 (CNN.v:318)         |
|                |                |            | lt_346 (CNN.v:346)         |
| gt_x_1169      | DW_cmp         | width=8    | gt_425 (CNN.v:425)         |
|                |                |            | gt_514 (CNN.v:514)         |
|                |                |            | gt_594 (CNN.v:594)         |
| lt_x_1170      | DW_cmp         | width=8    | lt_425 (CNN.v:425)         |
|                |                |            | lt_514 (CNN.v:514)         |
|                |                |            | lt_594 (CNN.v:594)         |
| gt_x_1171      | DW_cmp         | width=8    | gt_682 (CNN.v:682)         |
|                |                |            | gt_749 (CNN.v:749)         |
| gt_x_1172      | DW_cmp         | width=8    | gt_436 (CNN.v:436)         |
|                |                |            | gt_519 (CNN.v:519)         |
|                |                |            | gt_615 (CNN.v:615)         |
| lt_x_1173      | DW_cmp         | width=8    | lt_436 (CNN.v:436)         |
|                |                |            | lt_519 (CNN.v:519)         |
|                |                |            | lt_615 (CNN.v:615)         |
| gt_x_1174      | DW_cmp         | width=8    | gt_460 (CNN.v:460)         |
|                |                |            | gt_524 (CNN.v:524)         |
|                |                |            | gt_636 (CNN.v:636)         |
| lt_x_1175      | DW_cmp         | width=8    | lt_460 (CNN.v:460)         |
|                |                |            | lt_524 (CNN.v:524)         |
|                |                |            | lt_636 (CNN.v:636)         |
| gt_x_1176      | DW_cmp         | width=8    | gt_686 (CNN.v:686)         |
|                |                |            | gt_772 (CNN.v:772)         |
| gt_x_1177      | DW_cmp         | width=8    | gt_471 (CNN.v:471)         |
|                |                |            | gt_529 (CNN.v:529)         |
|                |                |            | gt_657 (CNN.v:657)         |
| lt_x_1178      | DW_cmp         | width=8    | lt_471 (CNN.v:471)         |
|                |                |            | lt_529 (CNN.v:529)         |
|                |                |            | lt_657 (CNN.v:657)         |
| gt_x_1179      | DW_cmp         | width=8    | gt_1014 (CNN.v:1014)       |
|                |                |            | gt_495 (CNN.v:495)         |
|                |                |            | gt_534 (CNN.v:534)         |
|                |                |            | gt_574 (CNN.v:574)         |
| lt_x_1180      | DW_cmp         | width=8    | lt_1014 (CNN.v:1014)       |
|                |                |            | lt_495 (CNN.v:495)         |
|                |                |            | lt_534 (CNN.v:534)         |
|                |                |            | lt_574 (CNN.v:574)         |
| gt_x_1181      | DW_cmp         | width=8    | gt_1050 (CNN.v:1050)       |
|                |                |            | gt_504 (CNN.v:504)         |
|                |                |            | gt_556 (CNN.v:556)         |
|                |                |            | gt_573 (CNN.v:573)         |
| lt_x_1182      | DW_cmp         | width=8    | lt_1050 (CNN.v:1050)       |
|                |                |            | lt_504 (CNN.v:504)         |
|                |                |            | lt_556 (CNN.v:556)         |
|                |                |            | lt_573 (CNN.v:573)         |
| lt_x_1183      | DW_cmp         | width=8    | lt_682 (CNN.v:682)         |
|                |                |            | lt_710 (CNN.v:710)         |
|                |                |            | lt_749 (CNN.v:749)         |
| lt_x_1184      | DW_cmp         | width=8    | lt_686 (CNN.v:686)         |
|                |                |            | lt_726 (CNN.v:726)         |
|                |                |            | lt_772 (CNN.v:772)         |
| gt_x_1185      | DW_cmp         | width=8    | gt_1246 (CNN.v:1246)       |
|                |                |            | gt_1255 (CNN.v:1255)       |
| sub_x_137      | DW01_sub       | width=9    | sub_473 (CNN.v:473)        |
|                |                |            | sub_473_2 (CNN.v:473)      |
|                |                |            | sub_474 (CNN.v:474)        |
|                |                |            | sub_474_2 (CNN.v:474)      |
|                |                |            | sub_475 (CNN.v:475)        |
|                |                |            | sub_475_2 (CNN.v:475)      |
|                |                |            | sub_476 (CNN.v:476)        |
|                |                |            | sub_476_2 (CNN.v:476)      |
|                |                |            | sub_477 (CNN.v:477)        |
|                |                |            | sub_477_2 (CNN.v:477)      |
|                |                |            | sub_478 (CNN.v:478)        |
|                |                |            | sub_478_2 (CNN.v:478)      |
|                |                |            | sub_479 (CNN.v:479)        |
|                |                |            | sub_479_2 (CNN.v:479)      |
|                |                |            | sub_480 (CNN.v:480)        |
|                |                |            | sub_480_2 (CNN.v:480)      |
|                |                |            | sub_481 (CNN.v:481)        |
|                |                |            | sub_481_2 (CNN.v:481)      |
|                |                |            | sub_484 (CNN.v:484)        |
|                |                |            | sub_484_2 (CNN.v:484)      |
|                |                |            | sub_485 (CNN.v:485)        |
|                |                |            | sub_485_2 (CNN.v:485)      |
|                |                |            | sub_486 (CNN.v:486)        |
|                |                |            | sub_486_2 (CNN.v:486)      |
|                |                |            | sub_487 (CNN.v:487)        |
|                |                |            | sub_487_2 (CNN.v:487)      |
|                |                |            | sub_488 (CNN.v:488)        |
|                |                |            | sub_488_2 (CNN.v:488)      |
|                |                |            | sub_489 (CNN.v:489)        |
|                |                |            | sub_489_2 (CNN.v:489)      |
|                |                |            | sub_490 (CNN.v:490)        |
|                |                |            | sub_490_2 (CNN.v:490)      |
|                |                |            | sub_491 (CNN.v:491)        |
|                |                |            | sub_491_2 (CNN.v:491)      |
|                |                |            | sub_492 (CNN.v:492)        |
|                |                |            | sub_492_2 (CNN.v:492)      |
| sub_x_123      | DW01_sub       | width=9    | sub_438 (CNN.v:438)        |
|                |                |            | sub_438_2 (CNN.v:438)      |
|                |                |            | sub_439 (CNN.v:439)        |
|                |                |            | sub_439_2 (CNN.v:439)      |
|                |                |            | sub_440 (CNN.v:440)        |
|                |                |            | sub_440_2 (CNN.v:440)      |
|                |                |            | sub_441 (CNN.v:441)        |
|                |                |            | sub_441_2 (CNN.v:441)      |
|                |                |            | sub_442 (CNN.v:442)        |
|                |                |            | sub_442_2 (CNN.v:442)      |
|                |                |            | sub_443 (CNN.v:443)        |
|                |                |            | sub_443_2 (CNN.v:443)      |
|                |                |            | sub_444 (CNN.v:444)        |
|                |                |            | sub_444_2 (CNN.v:444)      |
|                |                |            | sub_445 (CNN.v:445)        |
|                |                |            | sub_445_2 (CNN.v:445)      |
|                |                |            | sub_446 (CNN.v:446)        |
|                |                |            | sub_446_2 (CNN.v:446)      |
|                |                |            | sub_449 (CNN.v:449)        |
|                |                |            | sub_449_2 (CNN.v:449)      |
|                |                |            | sub_450 (CNN.v:450)        |
|                |                |            | sub_450_2 (CNN.v:450)      |
|                |                |            | sub_451 (CNN.v:451)        |
|                |                |            | sub_451_2 (CNN.v:451)      |
|                |                |            | sub_452 (CNN.v:452)        |
|                |                |            | sub_452_2 (CNN.v:452)      |
|                |                |            | sub_453 (CNN.v:453)        |
|                |                |            | sub_453_2 (CNN.v:453)      |
|                |                |            | sub_454 (CNN.v:454)        |
|                |                |            | sub_454_2 (CNN.v:454)      |
|                |                |            | sub_455 (CNN.v:455)        |
|                |                |            | sub_455_2 (CNN.v:455)      |
|                |                |            | sub_456 (CNN.v:456)        |
|                |                |            | sub_456_2 (CNN.v:456)      |
|                |                |            | sub_457 (CNN.v:457)        |
|                |                |            | sub_457_2 (CNN.v:457)      |
| sub_x_130      | DW01_sub       | width=9    | sub_461 (CNN.v:461)        |
|                |                |            | sub_461_2 (CNN.v:461)      |
|                |                |            | sub_462 (CNN.v:462)        |
|                |                |            | sub_462_2 (CNN.v:462)      |
|                |                |            | sub_463 (CNN.v:463)        |
|                |                |            | sub_463_2 (CNN.v:463)      |
|                |                |            | sub_464 (CNN.v:464)        |
|                |                |            | sub_464_2 (CNN.v:464)      |
|                |                |            | sub_465 (CNN.v:465)        |
|                |                |            | sub_465_2 (CNN.v:465)      |
|                |                |            | sub_466 (CNN.v:466)        |
|                |                |            | sub_466_2 (CNN.v:466)      |
|                |                |            | sub_467 (CNN.v:467)        |
|                |                |            | sub_467_2 (CNN.v:467)      |
|                |                |            | sub_468 (CNN.v:468)        |
|                |                |            | sub_468_2 (CNN.v:468)      |
|                |                |            | sub_469 (CNN.v:469)        |
|                |                |            | sub_469_2 (CNN.v:469)      |
| sub_x_116      | DW01_sub       | width=9    | sub_426 (CNN.v:426)        |
|                |                |            | sub_426_2 (CNN.v:426)      |
|                |                |            | sub_427 (CNN.v:427)        |
|                |                |            | sub_427_2 (CNN.v:427)      |
|                |                |            | sub_428 (CNN.v:428)        |
|                |                |            | sub_428_2 (CNN.v:428)      |
|                |                |            | sub_429 (CNN.v:429)        |
|                |                |            | sub_429_2 (CNN.v:429)      |
|                |                |            | sub_430 (CNN.v:430)        |
|                |                |            | sub_430_2 (CNN.v:430)      |
|                |                |            | sub_431 (CNN.v:431)        |
|                |                |            | sub_431_2 (CNN.v:431)      |
|                |                |            | sub_432 (CNN.v:432)        |
|                |                |            | sub_432_2 (CNN.v:432)      |
|                |                |            | sub_433 (CNN.v:433)        |
|                |                |            | sub_433_2 (CNN.v:433)      |
|                |                |            | sub_434 (CNN.v:434)        |
|                |                |            | sub_434_2 (CNN.v:434)      |
| sub_x_171      | DW01_sub       | width=3    | sub_535 (CNN.v:535)        |
|                |                |            | sub_536 (CNN.v:536)        |
|                |                |            | sub_537 (CNN.v:537)        |
|                |                |            | sub_538 (CNN.v:538)        |
|                |                |            | sub_539 (CNN.v:539)        |
|                |                |            | sub_540 (CNN.v:540)        |
|                |                |            | sub_541 (CNN.v:541)        |
|                |                |            | sub_542 (CNN.v:542)        |
| sub_x_192      | DW01_sub       | width=9    | sub_687 (CNN.v:687)        |
|                |                |            | sub_687_2 (CNN.v:687)      |
| sub_x_55       | DW01_sub       | width=9    | sub_285 (CNN.v:285)        |
|                |                |            | sub_285_2 (CNN.v:285)      |
| sub_x_189      | DW01_sub       | width=9    | sub_683 (CNN.v:683)        |
|                |                |            | sub_683_2 (CNN.v:683)      |
| div_117        | DW_div_uns     | a_width=32 | div_426 (CNN.v:426)        |
|                |                | b_width=3  | div_427 (CNN.v:427)        |
|                |                |            | div_428 (CNN.v:428)        |
|                |                |            | div_429 (CNN.v:429)        |
|                |                |            | div_430 (CNN.v:430)        |
|                |                |            | div_431 (CNN.v:431)        |
|                |                |            | div_432 (CNN.v:432)        |
|                |                |            | div_433 (CNN.v:433)        |
|                |                |            | div_434 (CNN.v:434)        |
| rem_118        | DW_div_uns     | a_width=32 | rem_426 (CNN.v:426)        |
|                |                | b_width=3  | rem_427 (CNN.v:427)        |
|                |                |            | rem_428 (CNN.v:428)        |
|                |                |            | rem_429 (CNN.v:429)        |
|                |                |            | rem_430 (CNN.v:430)        |
|                |                |            | rem_431 (CNN.v:431)        |
|                |                |            | rem_432 (CNN.v:432)        |
|                |                |            | rem_433 (CNN.v:433)        |
|                |                |            | rem_434 (CNN.v:434)        |
| div_124        | DW_div_uns     | a_width=32 | div_438 (CNN.v:438)        |
|                |                | b_width=3  | div_439 (CNN.v:439)        |
|                |                |            | div_440 (CNN.v:440)        |
|                |                |            | div_441 (CNN.v:441)        |
|                |                |            | div_442 (CNN.v:442)        |
|                |                |            | div_443 (CNN.v:443)        |
|                |                |            | div_444 (CNN.v:444)        |
|                |                |            | div_445 (CNN.v:445)        |
|                |                |            | div_446 (CNN.v:446)        |
|                |                |            | div_449 (CNN.v:449)        |
|                |                |            | div_450 (CNN.v:450)        |
|                |                |            | div_451 (CNN.v:451)        |
|                |                |            | div_452 (CNN.v:452)        |
|                |                |            | div_453 (CNN.v:453)        |
|                |                |            | div_454 (CNN.v:454)        |
|                |                |            | div_455 (CNN.v:455)        |
|                |                |            | div_456 (CNN.v:456)        |
|                |                |            | div_457 (CNN.v:457)        |
| rem_125        | DW_div_uns     | a_width=32 | rem_438 (CNN.v:438)        |
|                |                | b_width=3  | rem_439 (CNN.v:439)        |
|                |                |            | rem_440 (CNN.v:440)        |
|                |                |            | rem_441 (CNN.v:441)        |
|                |                |            | rem_442 (CNN.v:442)        |
|                |                |            | rem_443 (CNN.v:443)        |
|                |                |            | rem_444 (CNN.v:444)        |
|                |                |            | rem_445 (CNN.v:445)        |
|                |                |            | rem_446 (CNN.v:446)        |
|                |                |            | rem_449 (CNN.v:449)        |
|                |                |            | rem_450 (CNN.v:450)        |
|                |                |            | rem_451 (CNN.v:451)        |
|                |                |            | rem_452 (CNN.v:452)        |
|                |                |            | rem_453 (CNN.v:453)        |
|                |                |            | rem_454 (CNN.v:454)        |
|                |                |            | rem_455 (CNN.v:455)        |
|                |                |            | rem_456 (CNN.v:456)        |
|                |                |            | rem_457 (CNN.v:457)        |
| div_131        | DW_div_uns     | a_width=32 | div_461 (CNN.v:461)        |
|                |                | b_width=3  | div_462 (CNN.v:462)        |
|                |                |            | div_463 (CNN.v:463)        |
|                |                |            | div_464 (CNN.v:464)        |
|                |                |            | div_465 (CNN.v:465)        |
|                |                |            | div_466 (CNN.v:466)        |
|                |                |            | div_467 (CNN.v:467)        |
|                |                |            | div_468 (CNN.v:468)        |
|                |                |            | div_469 (CNN.v:469)        |
| rem_132        | DW_div_uns     | a_width=32 | rem_461 (CNN.v:461)        |
|                |                | b_width=3  | rem_462 (CNN.v:462)        |
|                |                |            | rem_463 (CNN.v:463)        |
|                |                |            | rem_464 (CNN.v:464)        |
|                |                |            | rem_465 (CNN.v:465)        |
|                |                |            | rem_466 (CNN.v:466)        |
|                |                |            | rem_467 (CNN.v:467)        |
|                |                |            | rem_468 (CNN.v:468)        |
|                |                |            | rem_469 (CNN.v:469)        |
| div_138        | DW_div_uns     | a_width=32 | div_473 (CNN.v:473)        |
|                |                | b_width=3  | div_474 (CNN.v:474)        |
|                |                |            | div_475 (CNN.v:475)        |
|                |                |            | div_476 (CNN.v:476)        |
|                |                |            | div_477 (CNN.v:477)        |
|                |                |            | div_478 (CNN.v:478)        |
|                |                |            | div_479 (CNN.v:479)        |
|                |                |            | div_480 (CNN.v:480)        |
|                |                |            | div_481 (CNN.v:481)        |
|                |                |            | div_484 (CNN.v:484)        |
|                |                |            | div_485 (CNN.v:485)        |
|                |                |            | div_486 (CNN.v:486)        |
|                |                |            | div_487 (CNN.v:487)        |
|                |                |            | div_488 (CNN.v:488)        |
|                |                |            | div_489 (CNN.v:489)        |
|                |                |            | div_490 (CNN.v:490)        |
|                |                |            | div_491 (CNN.v:491)        |
|                |                |            | div_492 (CNN.v:492)        |
| rem_139        | DW_div_uns     | a_width=32 | rem_473 (CNN.v:473)        |
|                |                | b_width=3  | rem_474 (CNN.v:474)        |
|                |                |            | rem_475 (CNN.v:475)        |
|                |                |            | rem_476 (CNN.v:476)        |
|                |                |            | rem_477 (CNN.v:477)        |
|                |                |            | rem_478 (CNN.v:478)        |
|                |                |            | rem_479 (CNN.v:479)        |
|                |                |            | rem_480 (CNN.v:480)        |
|                |                |            | rem_481 (CNN.v:481)        |
|                |                |            | rem_484 (CNN.v:484)        |
|                |                |            | rem_485 (CNN.v:485)        |
|                |                |            | rem_486 (CNN.v:486)        |
|                |                |            | rem_487 (CNN.v:487)        |
|                |                |            | rem_488 (CNN.v:488)        |
|                |                |            | rem_489 (CNN.v:489)        |
|                |                |            | rem_490 (CNN.v:490)        |
|                |                |            | rem_491 (CNN.v:491)        |
|                |                |            | rem_492 (CNN.v:492)        |
| add_x_143      | DW01_add       | width=3    | add_479 (CNN.v:479)        |
|                |                |            | add_480 (CNN.v:480)        |
|                |                |            | add_481 (CNN.v:481)        |
|                |                |            | add_490 (CNN.v:490)        |
|                |                |            | add_491 (CNN.v:491)        |
|                |                |            | add_492 (CNN.v:492)        |
| add_x_129      | DW01_add       | width=3    | add_444 (CNN.v:444)        |
|                |                |            | add_445 (CNN.v:445)        |
|                |                |            | add_446 (CNN.v:446)        |
|                |                |            | add_455 (CNN.v:455)        |
|                |                |            | add_456 (CNN.v:456)        |
|                |                |            | add_457 (CNN.v:457)        |
| add_x_141      | DW01_add       | width=3    | add_475 (CNN.v:475)        |
|                |                |            | add_478_2 (CNN.v:478)      |
|                |                |            | add_481_2 (CNN.v:481)      |
|                |                |            | add_486 (CNN.v:486)        |
|                |                |            | add_489_2 (CNN.v:489)      |
|                |                |            | add_492_2 (CNN.v:492)      |
| add_x_127      | DW01_add       | width=3    | add_440 (CNN.v:440)        |
|                |                |            | add_443_2 (CNN.v:443)      |
|                |                |            | add_446_2 (CNN.v:446)      |
|                |                |            | add_451 (CNN.v:451)        |
|                |                |            | add_454_2 (CNN.v:454)      |
|                |                |            | add_457_2 (CNN.v:457)      |
| add_x_142      | DW01_inc       | width=3    | add_476 (CNN.v:476)        |
|                |                |            | add_477 (CNN.v:477)        |
|                |                |            | add_478 (CNN.v:478)        |
|                |                |            | add_487 (CNN.v:487)        |
|                |                |            | add_488 (CNN.v:488)        |
|                |                |            | add_489 (CNN.v:489)        |
| add_x_128      | DW01_inc       | width=3    | add_441 (CNN.v:441)        |
|                |                |            | add_442 (CNN.v:442)        |
|                |                |            | add_443 (CNN.v:443)        |
|                |                |            | add_452 (CNN.v:452)        |
|                |                |            | add_453 (CNN.v:453)        |
|                |                |            | add_454 (CNN.v:454)        |
| add_x_140      | DW01_inc       | width=3    | add_474 (CNN.v:474)        |
|                |                |            | add_477_2 (CNN.v:477)      |
|                |                |            | add_480_2 (CNN.v:480)      |
|                |                |            | add_485 (CNN.v:485)        |
|                |                |            | add_488_2 (CNN.v:488)      |
|                |                |            | add_491_2 (CNN.v:491)      |
| add_x_126      | DW01_inc       | width=3    | add_439 (CNN.v:439)        |
|                |                |            | add_442_2 (CNN.v:442)      |
|                |                |            | add_445_2 (CNN.v:445)      |
|                |                |            | add_450 (CNN.v:450)        |
|                |                |            | add_453_2 (CNN.v:453)      |
|                |                |            | add_456_2 (CNN.v:456)      |
| add_x_136      | DW01_add       | width=3    | add_467 (CNN.v:467)        |
|                |                |            | add_468 (CNN.v:468)        |
|                |                |            | add_469 (CNN.v:469)        |
| add_x_134      | DW01_add       | width=3    | add_463 (CNN.v:463)        |
|                |                |            | add_466_2 (CNN.v:466)      |
|                |                |            | add_469_2 (CNN.v:469)      |
| add_x_122      | DW01_add       | width=3    | add_432 (CNN.v:432)        |
|                |                |            | add_433 (CNN.v:433)        |
|                |                |            | add_434 (CNN.v:434)        |
| add_x_135      | DW01_inc       | width=3    | add_464 (CNN.v:464)        |
|                |                |            | add_465 (CNN.v:465)        |
|                |                |            | add_466 (CNN.v:466)        |
| add_x_120      | DW01_add       | width=3    | add_428 (CNN.v:428)        |
|                |                |            | add_431_2 (CNN.v:431)      |
|                |                |            | add_434_2 (CNN.v:434)      |
| add_x_133      | DW01_inc       | width=3    | add_462 (CNN.v:462)        |
|                |                |            | add_465_2 (CNN.v:465)      |
|                |                |            | add_468_2 (CNN.v:468)      |
| add_x_121      | DW01_inc       | width=3    | add_429 (CNN.v:429)        |
|                |                |            | add_430 (CNN.v:430)        |
|                |                |            | add_431 (CNN.v:431)        |
| add_x_119      | DW01_inc       | width=3    | add_427 (CNN.v:427)        |
|                |                |            | add_430_2 (CNN.v:430)      |
|                |                |            | add_433_2 (CNN.v:433)      |
| DP_OP_77_206_8530               |            |                            |
|                | DP_OP_77_206_8530 |         |                            |
| DP_OP_6433J1_148_3075           |            |                            |
|                | DP_OP_6433J1_148_3075 |     |                            |
| DP_OP_6434J1_149_5102           |            |                            |
|                | DP_OP_6434J1_149_5102 |     |                            |
=============================================================================

Datapath Report for DP_OP_77_206_8530
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_77_206_8530    | mult_403 add_410 add_431 mult_426 mult_418 add_550  |
|                      | add_551 add_549                                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 9     |                                          |
| I2    | PI   | Unsigned | 26    |                                          |
| I3    | PI   | Unsigned | 28    |                                          |
| I4    | PI   | Unsigned | 14    |                                          |
| I5    | PI   | Unsigned | 14    |                                          |
| T4    | IFO  | Unsigned | 35    | I1 * I2                                  |
| T35   | IFO  | Unsigned | 21    | T4[34:14]                                |
| T6    | IFO  | Unsigned | 28    | I5 * I5                                  |
| T38   | IFO  | Unsigned | 14    | T6[27:14]                                |
| T7    | IFO  | Unsigned | 28    | I4 * T38                                 |
| T39   | IFO  | Unsigned | 14    | T7[27:14]                                |
| T40   | IFO  | Unsigned | 25    | O2[27:3]                                 |
| O1    | PO   | Unsigned | 28    | I3 + T35                                 |
| O2    | PO   | Unsigned | 28    | O1 + T39                                 |
| O3    | PO   | Unsigned | 25    | T40 + $unsigned(2'b10)                   |
| O4    | PO   | Unsigned | 25    | T40 + $unsigned(2'b11)                   |
| O5    | PO   | Unsigned | 25    | T40 + $unsigned(1'b1)                    |
==============================================================================

Datapath Report for DP_OP_6433J1_148_3075
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_6433J1_148_3075 | add_1171 (CNN.v:1171) add_1175 (CNN.v:1175)        |
|                      | add_1175_2 (CNN.v:1175) add_1179 (CNN.v:1179)       |
|                      | add_1179_2 (CNN.v:1179) add_1183 (CNN.v:1183)       |
|                      | add_1183_2 (CNN.v:1183) add_1183_3 (CNN.v:1183)     |
|                      | C50770 (CNN.v:1168) C50771 (CNN.v:1168)             |
|                      | add_1173 (CNN.v:1173) add_1174 (CNN.v:1174)         |
|                      | add_1177 (CNN.v:1177) add_1178 (CNN.v:1178)         |
|                      | add_1180 (CNN.v:1180) add_1181 (CNN.v:1181)         |
|                      | add_1181_2 (CNN.v:1181) add_1182 (CNN.v:1182)       |
|                      | add_1182_2 (CNN.v:1182) lte_1246 (CNN.v:1246)       |
|                      | lte_1255 (CNN.v:1255)                               |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 4     |                                          |
| I2    | PI   | Unsigned | 4     |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| I5    | PI   | Unsigned | 1     |                                          |
| I6    | PI   | Unsigned | 6     |                                          |
| I7    | PI   | Unsigned | 1     |                                          |
| I8    | PI   | Unsigned | 4     |                                          |
| I9    | PI   | Unsigned | 4     |                                          |
| I10   | PI   | Unsigned | 4     |                                          |
| I11   | PI   | Unsigned | 4     |                                          |
| I12   | PI   | Unsigned | 4     |                                          |
| T6413 | IFO  | Unsigned | 5     | I8 + I9 ( CNN.v:1173 CNN.v:1174 CNN.v:1177 CNN.v:1178 ) |
| T6423 | IFO  | Unsigned | 6     | { I3, I4, I5, I7 } ? O1 : T6413 : O2 : I6 (CNN.v:1168) |
| O1    | PO   | Unsigned | 5     | I1 + I2 ( CNN.v:1171 CNN.v:1175 CNN.v:1179 CNN.v:1183 ) |
| O2    | PO   | Unsigned | 5     | I10 + I11 ( CNN.v:1180 CNN.v:1181 CNN.v:1182 CNN.v:1183 ) |
| O3    | PO   | Unsigned | 1     | T6423 <= I12 ( CNN.v:1246 CNN.v:1255 )   |
==============================================================================

Datapath Report for DP_OP_6434J1_149_5102
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_6434J1_149_5102 | add_1175 (CNN.v:1175) add_1175_2 (CNN.v:1175)      |
|                      | add_1179 (CNN.v:1179) add_1179_2 (CNN.v:1179)       |
|                      | add_1181 (CNN.v:1181) add_1181_2 (CNN.v:1181)       |
|                      | add_1182 (CNN.v:1182) add_1182_2 (CNN.v:1182)       |
|                      | add_1183 (CNN.v:1183) add_1183_2 (CNN.v:1183)       |
|                      | add_1183_3 (CNN.v:1183)                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 5     |                                          |
| I2    | PI   | Unsigned | 5     |                                          |
| O1    | PO   | Unsigned | 6     | I1 + I2 ( CNN.v:1175 CNN.v:1179 CNN.v:1181 CNN.v:1182 CNN.v:1183 ) |
==============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare1 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare2 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare3 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare4 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare5 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare6 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare7 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy Maxpooling/compare8 in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy comparemax in file
        ./DW_fp_cmp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gt_x_3         | DW_cmp         | width=23   | gt_219                     |
| eq_x_4         | DW_cmp         | width=23   | eq_222                     |
| gt_x_5         | DW_cmp         | width=8    | gt_227                     |
| eq_x_6         | DW_cmp         | width=8    | eq_230                     |
=============================================================================


Resource Report for Ungrouped Hierarchy selectmax in file
        ./DW_fp_sum4__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_13       | DW_cmp         | width=32   | gte_478                    |
| gte_x_14       | DW_cmp         | width=32   | gte_481                    |
| gte_x_15       | DW_cmp         | width=32   | gte_484                    |
| gte_x_16       | DW_cmp         | width=32   | gte_486                    |
| gte_x_17       | DW_cmp         | width=32   | gte_488                    |
| eq_x_18        | DW_cmp         | width=32   | eq_490                     |
| eq_x_19        | DW_cmp         | width=32   | eq_491                     |
| eq_x_20        | DW_cmp         | width=32   | eq_492                     |
| eq_x_21        | DW_cmp         | width=32   | eq_493                     |
| eq_x_22        | DW_cmp         | width=32   | eq_494                     |
| sub_x_28       | DW01_sub       | width=8    | sub_507                    |
| sub_x_29       | DW01_sub       | width=8    | sub_508                    |
| sub_x_30       | DW01_sub       | width=8    | sub_509                    |
| add_x_31       | DW01_add       | width=9    | add_510                    |
| ashr_34        | DW_rightsh     | A_width=51 | srl_522                    |
|                |                | SH_width=8 |                            |
| ash_35         | DW_leftsh      | A_width=51 | sll_524                    |
|                |                | SH_width=8 |                            |
| ashr_36        | DW_rightsh     | A_width=51 | srl_532                    |
|                |                | SH_width=8 |                            |
| ash_37         | DW_leftsh      | A_width=51 | sll_533                    |
|                |                | SH_width=8 |                            |
| ashr_38        | DW_rightsh     | A_width=51 | srl_542                    |
|                |                | SH_width=8 |                            |
| ash_39         | DW_leftsh      | A_width=51 | sll_543                    |
|                |                | SH_width=8 |                            |
| ash_48         | DW_leftsh      | A_width=53 | sll_601                    |
|                |                | SH_width=7 |                            |
| add_x_50       | DW01_add       | width=25   | add_614                    |
| U3             | DW_fp_ifp_conv | sig_widthi=23 | U3                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U4             | DW_fp_ifp_conv | sig_widthi=23 | U4                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U5             | DW_fp_ifp_conv | sig_widthi=23 | U5                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U6             | DW_fp_ifp_conv | sig_widthi=23 | U6                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U7             | DW_ifp_addsub  | sig_widthi=25 | U7                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U8             | DW_ifp_addsub  | sig_widthi=25 | U8                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U9             | DW_ifp_addsub  | sig_widthi=28 | U9                      |
|                |                | exp_widthi=9 |                          |
|                |                | sig_widtho=51 |                         |
|                |                | exp_widtho=10 |                         |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U10            | DW_ifp_fp_conv | sig_widthi=51 | U10                     |
|                |                | exp_widthi=10 |                         |
|                |                | sig_width=23 |                          |
|                |                | exp_width=8 |                           |
|                |                | use_denormal=0 |                        |
| U1             | DW_lzd         | a_width=53 | U1                         |
| U2             | DW_lzd         | a_width=29 | U2                         |
| add_x_65       | DW01_inc       | width=11   | add_604 sub_604            |
| sub_x_49       | DW01_sub       | width=10   | add_604 sub_603 sub_604    |
| sub_x_66       | DW01_sub       | width=53   | add_577_ni sub_add_577     |
| add_x_67       | DW01_add       | width=2    | add_571 add_571_2          |
|                |                |            | add_571_3 add_571_4        |
|                |                |            | add_571_5 add_571_6        |
| add_x_69       | DW01_add       | width=53   | add_571 add_571_2          |
|                |                |            | add_571_3 add_571_4        |
|                |                |            | add_571_5 add_571_6        |
| add_x_70       | DW01_add       | width=53   | add_571 add_571_2          |
|                |                |            | add_571_3 add_571_4        |
|                |                |            | add_571_5 add_571_6        |
| add_x_71       | DW01_add       | width=54   | add_571 add_571_2          |
|                |                |            | add_571_3 add_571_4        |
|                |                |            | add_571_5 add_571_6        |
| add_x_72       | DW01_add       | width=54   | add_571 add_571_2          |
|                |                |            | add_571_3 add_571_4        |
|                |                |            | add_571_5 add_571_6        |
=============================================================================


Resource Report for Ungrouped Hierarchy recip_1 in file ./DW_fp_recip__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| mult_x_2       | DW_mult_uns    | a_width=25 | mult_399                   |
|                |                | b_width=9  |                            |
| mult_x_3       | DW_mult_uns    | a_width=25 | mult_552                   |
|                |                | b_width=25 |                            |
| gte_x_9        | DW_cmp         | width=9    | gte_649                    |
| eq_x_14        | DW_cmp         | width=10   | eq_650 eq_678              |
| DP_OP_79J1_123_5437             |            |                            |
|                | DP_OP_79J1_123_5437 |       |                            |
=============================================================================

Datapath Report for DP_OP_79J1_123_5437
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_79J1_123_5437  | sub_342 add_342 sub_574_ni                          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 1     |                                          |
| O1    | PO   | Signed   | 10    | -I1 - I2 + $unsigned(10'b0011111110)     |
==============================================================================


Resource Report for Ungrouped Hierarchy add_son
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| U1             | DW_fp_addsub   | sig_width=23 | U1                       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
=============================================================================


Resource Report for Ungrouped Hierarchy add_mom
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| U1             | DW_fp_addsub   | sig_width=23 | U1                       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
=============================================================================


Resource Report for Ungrouped Hierarchy exp_1/U2 in file ./DW_exp2__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| DP_OP_95J1_131_8617             |            |                            |
|                | DP_OP_95J1_131_8617 |       |                            |
=============================================================================

Datapath Report for DP_OP_95J1_131_8617
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_95J1_131_8617  | mult_3595 add_3595 mult_3597 add_3597 add_3600      |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 29    |                                          |
| I2    | PI   | Signed   | 27    |                                          |
| I3    | PI   | Unsigned | 56    |                                          |
| I4    | PI   | Unsigned | 26    |                                          |
| I5    | PI   | Unsigned | 53    |                                          |
| T83   | IFO  | Signed   | 57    | I1 * I2                                  |
| T84   | IFO  | Signed   | 58    | T83 + I3                                 |
| T90   | IFO  | Signed   | 32    | T84[57:26]                               |
| T85   | IFO  | Signed   | 56    | T90 * I4                                 |
| T86   | IFO  | Unsigned | 56    | T85 + I5                                 |
| T92   | IFO  | Unsigned | 28    | T86[55:28]                               |
| O1    | PO   | Unsigned | 28    | T92 + $unsigned(2'b10)                   |
==============================================================================


Resource Report for Ungrouped Hierarchy exp_1 in file ./DW_fp_exp__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| mult_x_4       | DW_mult_uns    | a_width=33 | mult_219                   |
|                |                | b_width=33 |                            |
| sub_x_5        | DW01_sub       | width=9    | sub_221                    |
| gte_x_6        | DW_cmp         | width=9    | gte_232                    |
| add_x_9        | DW01_add       | width=26   | add_270                    |
| add_x_11       | DW01_inc       | width=24   | add_276_round              |
| U1             | DW01_ash       | A_width=41 | U1                         |
|                |                | SH_width=9 |                            |
| U2             | DW_exp2        | op_width=26 | U2                        |
|                |                | arch=2     |                            |
|                |                | err_range=1 |                           |
| sub_x_16       | DW01_sub       | width=10   | add_242 sub_242            |
| add_x_17       | DW01_dec       | width=2    | add_247_ni_ni sub_add_247  |
| sub_x_18       | DW01_sub       | width=26   | add_247_ni_ni sub_add_247  |
| add_x_19       | DW01_add       | width=8    | add_260 add_261            |
| add_x_20       | DW01_add       | width=10   | add_260 add_261            |
=============================================================================


Resource Report for Ungrouped Hierarchy add_1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| U1             | DW_fp_addsub   | sig_width=23 | U1                       |
|                |                | exp_width=8 |                           |
|                |                | ieee_compliance=0 |                     |
=============================================================================


Resource Report for Ungrouped Hierarchy sum3_4 in file ./DW_fp_sum3__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| eq_x_4         | DW_cmp         | width=31   | eq_400                     |
| eq_x_5         | DW_cmp         | width=31   | eq_411                     |
| eq_x_6         | DW_cmp         | width=31   | eq_422                     |
| gte_x_17       | DW_cmp         | width=8    | gte_452                    |
| gte_x_18       | DW_cmp         | width=8    | gte_452_2                  |
| gte_x_19       | DW_cmp         | width=8    | gte_454                    |
| gte_x_20       | DW_cmp         | width=8    | gte_454_2                  |
| sub_x_21       | DW01_sub       | width=8    | sub_458                    |
| sub_x_22       | DW01_sub       | width=8    | sub_459                    |
| sub_x_23       | DW01_sub       | width=8    | sub_460                    |
| ashr_28        | DW_rightsh     | A_width=51 | srl_470                    |
|                |                | SH_width=8 |                            |
| ash_29         | DW_leftsh      | A_width=51 | sll_472                    |
|                |                | SH_width=8 |                            |
| ashr_30        | DW_rightsh     | A_width=51 | srl_478                    |
|                |                | SH_width=8 |                            |
| ash_31         | DW_leftsh      | A_width=51 | sll_480                    |
|                |                | SH_width=8 |                            |
| ashr_32        | DW_rightsh     | A_width=51 | srl_486                    |
|                |                | SH_width=8 |                            |
| ash_33         | DW_leftsh      | A_width=51 | sll_488                    |
|                |                | SH_width=8 |                            |
| gt_x_34        | DW_cmp         | width=32   | gt_498                     |
| gt_x_35        | DW_cmp         | width=32   | gt_503                     |
| gt_x_36        | DW_cmp         | width=32   | gt_508                     |
| ash_46         | DW_leftsh      | A_width=53 | sll_562                    |
|                |                | SH_width=7 |                            |
| add_x_47       | DW01_add       | width=25   | add_575                    |
| U2             | DW_fp_ifp_conv | sig_widthi=23 | U2                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U3             | DW_fp_ifp_conv | sig_widthi=23 | U3                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U4             | DW_fp_ifp_conv | sig_widthi=23 | U4                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U5             | DW_ifp_addsub  | sig_widthi=25 | U5                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U6             | DW_ifp_addsub  | sig_widthi=28 | U6                      |
|                |                | exp_widthi=9 |                          |
|                |                | sig_widtho=51 |                         |
|                |                | exp_widtho=10 |                         |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U7             | DW_ifp_fp_conv | sig_widthi=51 | U7                      |
|                |                | exp_widthi=10 |                         |
|                |                | sig_width=23 |                          |
|                |                | exp_width=8 |                           |
|                |                | use_denormal=0 |                        |
| U1             | DW_lzd         | a_width=53 | U1                         |
| DP_OP_160J1_136_9276            |            |                            |
|                | DP_OP_160J1_136_9276 |      |                            |
| DP_OP_161J1_137_406             |            |                            |
|                | DP_OP_161J1_137_406 |       |                            |
=============================================================================

Datapath Report for DP_OP_160J1_136_9276
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_160J1_136_9276 | add_461 sub_564 sub_565 add_565                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 7     |                                          |
| O1    | PO   | Unsigned | 9     | I1 + $unsigned(2'b10)                    |
| O2    | PO   | Signed   | 10    | O1 - I2                                  |
| O3    | PO   | Signed   | 11    | $unsigned(1'b1) + O2                     |
==============================================================================

Datapath Report for DP_OP_161J1_137_406
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_161J1_137_406  | add_532 add_532_2 add_532_3 add_532_4 sub_add_537   |
|                      | add_537_ni                                          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Signed   | 52    |                                          |
| I2    | PI   | Signed   | 52    |                                          |
| I3    | PI   | Unsigned | 51    |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| I5    | PI   | Unsigned | 1     |                                          |
| T159  | IFO  | Signed   | 53    | O1[52:0]                                 |
| O1    | PO   | Signed   | 54    | I1 + I2 + I3 + I4 + I5                   |
| O2    | PO   | Signed   | 53    | -T159 + $unsigned(53'b00000000000000000000000000000000000000000000000000000) |
==============================================================================


Resource Report for Ungrouped Hierarchy sum3_3 in file ./DW_fp_sum3__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| eq_x_4         | DW_cmp         | width=31   | eq_400                     |
| eq_x_5         | DW_cmp         | width=31   | eq_411                     |
| eq_x_6         | DW_cmp         | width=31   | eq_422                     |
| gte_x_17       | DW_cmp         | width=8    | gte_452                    |
| gte_x_18       | DW_cmp         | width=8    | gte_452_2                  |
| gte_x_19       | DW_cmp         | width=8    | gte_454                    |
| gte_x_20       | DW_cmp         | width=8    | gte_454_2                  |
| sub_x_21       | DW01_sub       | width=8    | sub_458                    |
| sub_x_22       | DW01_sub       | width=8    | sub_459                    |
| sub_x_23       | DW01_sub       | width=8    | sub_460                    |
| ashr_28        | DW_rightsh     | A_width=51 | srl_470                    |
|                |                | SH_width=8 |                            |
| ash_29         | DW_leftsh      | A_width=51 | sll_472                    |
|                |                | SH_width=8 |                            |
| ashr_30        | DW_rightsh     | A_width=51 | srl_478                    |
|                |                | SH_width=8 |                            |
| ash_31         | DW_leftsh      | A_width=51 | sll_480                    |
|                |                | SH_width=8 |                            |
| ashr_32        | DW_rightsh     | A_width=51 | srl_486                    |
|                |                | SH_width=8 |                            |
| ash_33         | DW_leftsh      | A_width=51 | sll_488                    |
|                |                | SH_width=8 |                            |
| gt_x_34        | DW_cmp         | width=32   | gt_498                     |
| gt_x_35        | DW_cmp         | width=32   | gt_503                     |
| gt_x_36        | DW_cmp         | width=32   | gt_508                     |
| ash_46         | DW_leftsh      | A_width=53 | sll_562                    |
|                |                | SH_width=7 |                            |
| add_x_47       | DW01_add       | width=25   | add_575                    |
| U2             | DW_fp_ifp_conv | sig_widthi=23 | U2                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U3             | DW_fp_ifp_conv | sig_widthi=23 | U3                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U4             | DW_fp_ifp_conv | sig_widthi=23 | U4                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U5             | DW_ifp_addsub  | sig_widthi=25 | U5                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U6             | DW_ifp_addsub  | sig_widthi=28 | U6                      |
|                |                | exp_widthi=9 |                          |
|                |                | sig_widtho=51 |                         |
|                |                | exp_widtho=10 |                         |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U7             | DW_ifp_fp_conv | sig_widthi=51 | U7                      |
|                |                | exp_widthi=10 |                         |
|                |                | sig_width=23 |                          |
|                |                | exp_width=8 |                           |
|                |                | use_denormal=0 |                        |
| U1             | DW_lzd         | a_width=53 | U1                         |
| DP_OP_160J1_139_9276            |            |                            |
|                | DP_OP_160J1_139_9276 |      |                            |
| DP_OP_161J1_140_406             |            |                            |
|                | DP_OP_161J1_140_406 |       |                            |
=============================================================================

Datapath Report for DP_OP_160J1_139_9276
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_160J1_139_9276 | add_461 sub_564 sub_565 add_565                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 7     |                                          |
| O1    | PO   | Unsigned | 9     | I1 + $unsigned(2'b10)                    |
| O2    | PO   | Signed   | 10    | O1 - I2                                  |
| O3    | PO   | Signed   | 11    | $unsigned(1'b1) + O2                     |
==============================================================================

Datapath Report for DP_OP_161J1_140_406
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_161J1_140_406  | add_532 add_532_2 add_532_3 add_532_4 sub_add_537   |
|                      | add_537_ni                                          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Signed   | 52    |                                          |
| I2    | PI   | Signed   | 52    |                                          |
| I3    | PI   | Unsigned | 51    |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| I5    | PI   | Unsigned | 1     |                                          |
| T159  | IFO  | Signed   | 53    | O1[52:0]                                 |
| O1    | PO   | Signed   | 54    | I1 + I2 + I3 + I4 + I5                   |
| O2    | PO   | Signed   | 53    | -T159 + $unsigned(53'b00000000000000000000000000000000000000000000000000000) |
==============================================================================


Resource Report for Ungrouped Hierarchy sum3_2 in file ./DW_fp_sum3__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| eq_x_4         | DW_cmp         | width=31   | eq_400                     |
| eq_x_5         | DW_cmp         | width=31   | eq_411                     |
| eq_x_6         | DW_cmp         | width=31   | eq_422                     |
| gte_x_17       | DW_cmp         | width=8    | gte_452                    |
| gte_x_18       | DW_cmp         | width=8    | gte_452_2                  |
| gte_x_19       | DW_cmp         | width=8    | gte_454                    |
| gte_x_20       | DW_cmp         | width=8    | gte_454_2                  |
| sub_x_21       | DW01_sub       | width=8    | sub_458                    |
| sub_x_22       | DW01_sub       | width=8    | sub_459                    |
| sub_x_23       | DW01_sub       | width=8    | sub_460                    |
| ashr_28        | DW_rightsh     | A_width=51 | srl_470                    |
|                |                | SH_width=8 |                            |
| ash_29         | DW_leftsh      | A_width=51 | sll_472                    |
|                |                | SH_width=8 |                            |
| ashr_30        | DW_rightsh     | A_width=51 | srl_478                    |
|                |                | SH_width=8 |                            |
| ash_31         | DW_leftsh      | A_width=51 | sll_480                    |
|                |                | SH_width=8 |                            |
| ashr_32        | DW_rightsh     | A_width=51 | srl_486                    |
|                |                | SH_width=8 |                            |
| ash_33         | DW_leftsh      | A_width=51 | sll_488                    |
|                |                | SH_width=8 |                            |
| gt_x_34        | DW_cmp         | width=32   | gt_498                     |
| gt_x_35        | DW_cmp         | width=32   | gt_503                     |
| gt_x_36        | DW_cmp         | width=32   | gt_508                     |
| ash_46         | DW_leftsh      | A_width=53 | sll_562                    |
|                |                | SH_width=7 |                            |
| add_x_47       | DW01_add       | width=25   | add_575                    |
| U2             | DW_fp_ifp_conv | sig_widthi=23 | U2                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U3             | DW_fp_ifp_conv | sig_widthi=23 | U3                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U4             | DW_fp_ifp_conv | sig_widthi=23 | U4                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U5             | DW_ifp_addsub  | sig_widthi=25 | U5                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U6             | DW_ifp_addsub  | sig_widthi=28 | U6                      |
|                |                | exp_widthi=9 |                          |
|                |                | sig_widtho=51 |                         |
|                |                | exp_widtho=10 |                         |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U7             | DW_ifp_fp_conv | sig_widthi=51 | U7                      |
|                |                | exp_widthi=10 |                         |
|                |                | sig_width=23 |                          |
|                |                | exp_width=8 |                           |
|                |                | use_denormal=0 |                        |
| U1             | DW_lzd         | a_width=53 | U1                         |
| DP_OP_160J1_142_9276            |            |                            |
|                | DP_OP_160J1_142_9276 |      |                            |
| DP_OP_161J1_143_406             |            |                            |
|                | DP_OP_161J1_143_406 |       |                            |
=============================================================================

Datapath Report for DP_OP_160J1_142_9276
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_160J1_142_9276 | add_461 sub_564 sub_565 add_565                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 7     |                                          |
| O1    | PO   | Unsigned | 9     | I1 + $unsigned(2'b10)                    |
| O2    | PO   | Signed   | 10    | O1 - I2                                  |
| O3    | PO   | Signed   | 11    | $unsigned(1'b1) + O2                     |
==============================================================================

Datapath Report for DP_OP_161J1_143_406
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_161J1_143_406  | add_532 add_532_2 add_532_3 add_532_4 sub_add_537   |
|                      | add_537_ni                                          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Signed   | 52    |                                          |
| I2    | PI   | Signed   | 52    |                                          |
| I3    | PI   | Unsigned | 51    |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| I5    | PI   | Unsigned | 1     |                                          |
| T159  | IFO  | Signed   | 53    | O1[52:0]                                 |
| O1    | PO   | Signed   | 54    | I1 + I2 + I3 + I4 + I5                   |
| O2    | PO   | Signed   | 53    | -T159 + $unsigned(53'b00000000000000000000000000000000000000000000000000000) |
==============================================================================


Resource Report for Ungrouped Hierarchy sum3_1 in file ./DW_fp_sum3__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| eq_x_4         | DW_cmp         | width=31   | eq_400                     |
| eq_x_5         | DW_cmp         | width=31   | eq_411                     |
| eq_x_6         | DW_cmp         | width=31   | eq_422                     |
| gte_x_17       | DW_cmp         | width=8    | gte_452                    |
| gte_x_18       | DW_cmp         | width=8    | gte_452_2                  |
| gte_x_19       | DW_cmp         | width=8    | gte_454                    |
| gte_x_20       | DW_cmp         | width=8    | gte_454_2                  |
| sub_x_21       | DW01_sub       | width=8    | sub_458                    |
| sub_x_22       | DW01_sub       | width=8    | sub_459                    |
| sub_x_23       | DW01_sub       | width=8    | sub_460                    |
| ashr_28        | DW_rightsh     | A_width=51 | srl_470                    |
|                |                | SH_width=8 |                            |
| ash_29         | DW_leftsh      | A_width=51 | sll_472                    |
|                |                | SH_width=8 |                            |
| ashr_30        | DW_rightsh     | A_width=51 | srl_478                    |
|                |                | SH_width=8 |                            |
| ash_31         | DW_leftsh      | A_width=51 | sll_480                    |
|                |                | SH_width=8 |                            |
| ashr_32        | DW_rightsh     | A_width=51 | srl_486                    |
|                |                | SH_width=8 |                            |
| ash_33         | DW_leftsh      | A_width=51 | sll_488                    |
|                |                | SH_width=8 |                            |
| gt_x_34        | DW_cmp         | width=32   | gt_498                     |
| gt_x_35        | DW_cmp         | width=32   | gt_503                     |
| gt_x_36        | DW_cmp         | width=32   | gt_508                     |
| ash_46         | DW_leftsh      | A_width=53 | sll_562                    |
|                |                | SH_width=7 |                            |
| add_x_47       | DW01_add       | width=25   | add_575                    |
| U2             | DW_fp_ifp_conv | sig_widthi=23 | U2                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U3             | DW_fp_ifp_conv | sig_widthi=23 | U3                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=25 |                         |
|                |                | exp_widtho=8 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U4             | DW_fp_ifp_conv | sig_widthi=23 | U4                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U5             | DW_ifp_addsub  | sig_widthi=25 | U5                      |
|                |                | exp_widthi=8 |                          |
|                |                | sig_widtho=28 |                         |
|                |                | exp_widtho=9 |                          |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U6             | DW_ifp_addsub  | sig_widthi=28 | U6                      |
|                |                | exp_widthi=9 |                          |
|                |                | sig_widtho=51 |                         |
|                |                | exp_widtho=10 |                         |
|                |                | use_denormal=0 |                        |
|                |                | use_1scmpl=0 |                          |
| U7             | DW_ifp_fp_conv | sig_widthi=51 | U7                      |
|                |                | exp_widthi=10 |                         |
|                |                | sig_width=23 |                          |
|                |                | exp_width=8 |                           |
|                |                | use_denormal=0 |                        |
| U1             | DW_lzd         | a_width=53 | U1                         |
| DP_OP_160J1_145_9276            |            |                            |
|                | DP_OP_160J1_145_9276 |      |                            |
| DP_OP_161J1_146_406             |            |                            |
|                | DP_OP_161J1_146_406 |       |                            |
=============================================================================

Datapath Report for DP_OP_160J1_145_9276
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_160J1_145_9276 | add_461 sub_564 sub_565 add_565                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 7     |                                          |
| O1    | PO   | Unsigned | 9     | I1 + $unsigned(2'b10)                    |
| O2    | PO   | Signed   | 10    | O1 - I2                                  |
| O3    | PO   | Signed   | 11    | $unsigned(1'b1) + O2                     |
==============================================================================

Datapath Report for DP_OP_161J1_146_406
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_161J1_146_406  | add_532 add_532_2 add_532_3 add_532_4 sub_add_537   |
|                      | add_537_ni                                          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Signed   | 52    |                                          |
| I2    | PI   | Signed   | 52    |                                          |
| I3    | PI   | Unsigned | 51    |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| I5    | PI   | Unsigned | 1     |                                          |
| T159  | IFO  | Signed   | 53    | O1[52:0]                                 |
| O1    | PO   | Signed   | 54    | I1 + I2 + I3 + I4 + I5                   |
| O2    | PO   | Signed   | 53    | -T159 + $unsigned(53'b00000000000000000000000000000000000000000000000000000) |
==============================================================================


Resource Report for Ungrouped Hierarchy div_193
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy div_190
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy div_138
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy div_131
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy div_124
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy div_117
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy div_56
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J10*295214/U1 in file
        ./DW_norm_rtl.vhd.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| U2             | DW01_ash       | A_width=27 | U2                         |
|                |                | SH_width=3 |                            |
=============================================================================


Resource Report for Ungrouped Hierarchy add_mom/U1 in file
        ./DW_fp_addsub__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| lt_x_1         | DW_cmp         | width=31   | lt_223                     |
| ashr_5         | DW_rightsh     | A_width=26 | srl_283_lsb_trim           |
|                |                | SH_width=8 |                            |
| ash_6          | DW_leftsh      | A_width=26 | sll_285                    |
|                |                | SH_width=8 |                            |
| ash_8          | DW_leftsh      | A_width=27 | sll_337                    |
|                |                | SH_width=6 |                            |
| add_x_9        | DW01_add       | width=5    | add_339                    |
| add_x_16       | DW01_inc       | width=23   | add_398                    |
| U2             | DW_lzd         | a_width=28 | U2                         |
| U1             | DW_norm        | a_width=27 | U1                         |
|                |                | srch_wind=3 |                           |
|                |                | exp_width=6 |                           |
|                |                | exp_ctr=0  |                            |
| DP_OP_65J10_199_7885            |            |                            |
|                | DP_OP_65J10_199_7885 |      |                            |
| DP_OP_66J10_200_3163            |            |                            |
|                | DP_OP_66J10_200_3163 |      |                            |
| DP_OP_67J10_201_9752            |            |                            |
|                | DP_OP_67J10_201_9752 |      |                            |
=============================================================================

Datapath Report for DP_OP_65J10_199_7885
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_65J10_199_7885 | sub_277 sub_add_279 add_279_ni                      |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T64   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 9     | I1 - I2                                  |
| O2    | PO   | Signed   | 8     | -T64 + $unsigned(8'b00000000)            |
==============================================================================

Datapath Report for DP_OP_66J10_200_3163
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_66J10_200_3163 | add_294 add_294_2                                   |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 27    |                                          |
| I2    | PI   | Unsigned | 28    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| O1    | PO   | Unsigned | 28    | I1 + I2 + I3                             |
==============================================================================

Datapath Report for DP_OP_67J10_201_9752
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_67J10_201_9752 | add_402 sub_403                                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 5     |                                          |
| O1    | PO   | Unsigned | 9     | I1 + $unsigned(1'b1)                     |
| O2    | PO   | Signed   | 10    | O1 - I2                                  |
==============================================================================


Resource Report for Ungrouped Hierarchy *cell*J12*297068/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J12*297068/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mult_1 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J12_196_7736           |            |                            |
|                | DP_OP_108J12_196_7736 |     |                            |
| DP_OP_109J12_197_8092           |            |                            |
|                | DP_OP_109J12_197_8092 |     |                            |
=============================================================================

Datapath Report for DP_OP_108J12_196_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J12_196_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400         |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J12_197_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J12_197_8092 | add_535 add_568 add_569                            |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy rem_139
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J9*277679/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J9*277679/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_6 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J9_155_7736            |            |                            |
|                | DP_OP_108J9_155_7736 |      |                            |
| DP_OP_109J9_156_8092            |            |                            |
|                | DP_OP_109J9_156_8092 |      |                            |
=============================================================================

Datapath Report for DP_OP_108J9_155_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J9_155_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J9_156_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J9_156_8092 | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy sum3_4/U1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy sum3_2/U1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J8*278193/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J8*278193/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_4 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J8_155_7736            |            |                            |
|                | DP_OP_108J8_155_7736 |      |                            |
| DP_OP_109J8_156_8092            |            |                            |
|                | DP_OP_109J8_156_8092 |      |                            |
=============================================================================

Datapath Report for DP_OP_108J8_155_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J8_155_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J8_156_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J8_156_8092 | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy *cell*287452/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*287452/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_5 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108_159_7736              |            |                            |
|                | DP_OP_108_159_7736 |        |                            |
| DP_OP_109_160_8092              |            |                            |
|                | DP_OP_109_160_8092 |        |                            |
=============================================================================

Datapath Report for DP_OP_108_159_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108_159_7736   | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109_160_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109_160_8092   | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy rem_125
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy rem_132
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy sum3_3/U1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J3*277616/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J3*277616/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_8 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J3_155_7736            |            |                            |
|                | DP_OP_108J3_155_7736 |      |                            |
| DP_OP_109J3_156_8092            |            |                            |
|                | DP_OP_109J3_156_8092 |      |                            |
=============================================================================

Datapath Report for DP_OP_108J3_155_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J3_155_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J3_156_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J3_156_8092 | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy *cell*277691/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*277691/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_9 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108_155_7736              |            |                            |
|                | DP_OP_108_155_7736 |        |                            |
| DP_OP_109_156_8092              |            |                            |
|                | DP_OP_109_156_8092 |        |                            |
=============================================================================

Datapath Report for DP_OP_108_155_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108_155_7736   | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109_156_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109_156_8092   | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy *cell*J4*277787/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J4*277787/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_7 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J4_155_7736            |            |                            |
|                | DP_OP_108J4_155_7736 |      |                            |
| DP_OP_109J4_156_8092            |            |                            |
|                | DP_OP_109J4_156_8092 |      |                            |
=============================================================================

Datapath Report for DP_OP_108J4_155_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J4_155_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J4_156_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J4_156_8092 | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy rem_118
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy sum3_1/U1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J6*277992/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J6*277992/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_2 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J6_155_7736            |            |                            |
|                | DP_OP_108J6_155_7736 |      |                            |
| DP_OP_109J6_156_8092            |            |                            |
|                | DP_OP_109J6_156_8092 |      |                            |
=============================================================================

Datapath Report for DP_OP_108J6_155_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J6_155_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J6_156_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J6_156_8092 | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy *cell*J7*278047/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J7*278047/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_3 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J7_155_7736            |            |                            |
|                | DP_OP_108J7_155_7736 |      |                            |
| DP_OP_109J7_156_8092            |            |                            |
|                | DP_OP_109J7_156_8092 |      |                            |
=============================================================================

Datapath Report for DP_OP_108J7_155_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J7_155_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J7_156_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J7_156_8092 | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy *cell*J4*287431/UL2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy *cell*J4*287431/UL1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_1 in file ./DW_fp_mult__str.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| gte_x_2        | DW_cmp         | width=9    | gte_401                    |
| gte_x_4        | DW_cmp         | width=9    | gte_403                    |
| add_x_11       | DW01_add       | width=7    | add_480_4                  |
| add_x_12       | DW01_add       | width=24   | add_528                    |
| add_x_13       | DW01_add       | width=26   | add_529                    |
| eq_x_14        | DW_cmp         | width=10   | eq_553                     |
| lt_x_21        | DW_cmp         | width=8    | lt_615                     |
| lt_x_23        | DW_cmp         | width=8    | lt_619                     |
| add_x_24       | DW01_add       | width=3    | add_622                    |
| add_x_25       | DW01_add       | width=2    | add_623_ni                 |
| UL3            | DW_lzd         | a_width=24 | UL3                        |
| UL4            | DW_lzd         | a_width=24 | UL4                        |
| UM1            | DW02_multp     | a_width=24 | UM1                        |
|                |                | b_width=24 |                            |
|                |                | out_width=50 |                          |
|                |                | verif_en=1 |                            |
| DP_OP_108J4_159_7736            |            |                            |
|                | DP_OP_108J4_159_7736 |      |                            |
| DP_OP_109J4_160_8092            |            |                            |
|                | DP_OP_109J4_160_8092 |      |                            |
=============================================================================

Datapath Report for DP_OP_108J4_159_7736
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_108J4_159_7736 | add_384_4 sub_384_3 add_387 lte_399 lt_400          |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 8     |                                          |
| T58   | IFO  | Signed   | 8     | O1[7:0]                                  |
| O1    | PO   | Signed   | 10    | I1 + I2 - $unsigned(7'b1111111)          |
| O2    | PO   | Unsigned | 8     | T58 + $unsigned(1'b1)                    |
| O3    | PO   | Signed   | 1     | O1 <= $signed(1'b0)                      |
| O4    | PO   | Signed   | 1     | O1 < $signed(1'b0)                       |
==============================================================================

Datapath Report for DP_OP_109J4_160_8092
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_109J4_160_8092 | add_535 add_568 add_569                             |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 23    |                                          |
| I2    | PI   | Unsigned | 23    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| I4    | PI   | Unsigned | 1     |                                          |
| T69   | IFO  | Signed   | 22    | O1[21:0]                                 |
| T71   | IFO  | Signed   | 21    | O1[20:0]                                 |
| O1    | PO   | Unsigned | 23    | I1 + I2                                  |
| O2    | PO   | Unsigned | 22    | T69 + I3                                 |
| O3    | PO   | Unsigned | 21    | T71 + I4                                 |
==============================================================================


Resource Report for Ungrouped Hierarchy add_son/U1 in file
        ./DW_fp_addsub__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| lt_x_1         | DW_cmp         | width=31   | lt_191                     |
| sub_x_4        | DW01_sub       | width=8    | sub_232                    |
| ashr_5         | DW_rightsh     | A_width=26 | srl_237_lsb_trim           |
|                |                | SH_width=8 |                            |
| ash_6          | DW_leftsh      | A_width=26 | sll_239                    |
|                |                | SH_width=8 |                            |
| ash_8          | DW_leftsh      | A_width=26 | sll_266                    |
|                |                | SH_width=5 |                            |
| add_x_12       | DW01_inc       | width=23   | add_303                    |
| U1             | DW_lzd         | a_width=27 | U1                         |
| DP_OP_49J1_126_3163             |            |                            |
|                | DP_OP_49J1_126_3163 |       |                            |
| DP_OP_50J1_127_9752             |            |                            |
|                | DP_OP_50J1_127_9752 |       |                            |
=============================================================================

Datapath Report for DP_OP_49J1_126_3163
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_49J1_126_3163  | add_249 add_249_2                                   |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 27    |                                          |
| I2    | PI   | Unsigned | 28    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| O1    | PO   | Unsigned | 28    | I1 + I2 + I3                             |
==============================================================================

Datapath Report for DP_OP_50J1_127_9752
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_50J1_127_9752  | add_306 sub_307                                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 5     |                                          |
| O1    | PO   | Unsigned | 9     | I1 + $unsigned(1'b1)                     |
| O2    | PO   | Signed   | 10    | O1 - I2                                  |
==============================================================================


Resource Report for Ungrouped Hierarchy rem_58
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy rem_14
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy div_12
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_8/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_9/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_6/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_7/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_3/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_4/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_2/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_5/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_1/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy add_mom/U1/U2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy selectmax/U1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mult_1/UL4
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_1/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_9/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_5/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_2/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_4/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_8/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_6/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_7/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mul_3/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy rem_194
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy rem_191
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy selectmax/U2
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy add_1/U1 in file
        ./DW_fp_addsub__rtl.v.e
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| lt_x_1         | DW_cmp         | width=31   | lt_191                     |
| sub_x_4        | DW01_sub       | width=8    | sub_232                    |
| ashr_5         | DW_rightsh     | A_width=26 | srl_237_lsb_trim           |
|                |                | SH_width=8 |                            |
| ash_6          | DW_leftsh      | A_width=26 | sll_239                    |
|                |                | SH_width=8 |                            |
| ash_8          | DW_leftsh      | A_width=26 | sll_266                    |
|                |                | SH_width=5 |                            |
| add_x_12       | DW01_inc       | width=23   | add_303                    |
| U1             | DW_lzd         | a_width=27 | U1                         |
| DP_OP_49J1_134_3163             |            |                            |
|                | DP_OP_49J1_134_3163 |       |                            |
| DP_OP_50J1_135_9752             |            |                            |
|                | DP_OP_50J1_135_9752 |       |                            |
=============================================================================

Datapath Report for DP_OP_49J1_134_3163
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_49J1_134_3163  | add_249 add_249_2                                   |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 27    |                                          |
| I2    | PI   | Unsigned | 28    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| O1    | PO   | Unsigned | 28    | I1 + I2 + I3                             |
==============================================================================

Datapath Report for DP_OP_50J1_135_9752
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_50J1_135_9752  | add_306 sub_307                                     |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Unsigned | 8     |                                          |
| I2    | PI   | Unsigned | 5     |                                          |
| O1    | PO   | Unsigned | 9     | I1 + $unsigned(1'b1)                     |
| O2    | PO   | Signed   | 10    | O1 - I2                                  |
==============================================================================


Resource Report for Ungrouped Hierarchy add_son/U1/U1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy add_1/U1/U1
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Resource Report for Ungrouped Hierarchy mult_1/UL3
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
=============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| add_x_1            | DW01_inc         | apparch (area)     |                |
| add_x_3            | DW01_inc         | apparch (area)     |                |
| lt_x_11            | DW_cmp           | apparch (area)     |                |
| div_12             | DW_div_uns       | cla                |                |
| add_x_13           | DW01_inc         | apparch (area)     |                |
| rem_14             | DW_div_uns       | cla                |                |
| add_x_15           | DW01_inc         | apparch (area)     |                |
| gte_x_53           | DW_cmp           | apparch (area)     |                |
| lt_x_54            | DW_cmp           | apparch (area)     |                |
| div_56             | DW_div_uns       | cla                |                |
| add_x_57           | DW01_inc         | apparch (area)     |                |
| rem_58             | DW_div_uns       | cla                |                |
| add_x_59           | DW01_inc         | apparch (area)     |                |
| lt_x_109           | DW_cmp           | apparch (area)     |                |
| lt_x_112           | DW_cmp           | apparch (area)     |                |
| gt_x_113           | DW_cmp           | apparch (area)     |                |
| gt_x_183           | DW_cmp           | apparch (area)     |                |
| lt_x_184           | DW_cmp           | apparch (area)     |                |
| gt_x_185           | DW_cmp           | apparch (area)     |                |
| gt_x_186           | DW_cmp           | apparch (area)     |                |
| lt_x_187           | DW_cmp           | apparch (area)     |                |
| gt_x_188           | DW_cmp           | apparch (area)     |                |
| div_190            | DW_div_uns       | cla                |                |
| rem_191            | DW_div_uns       | cla                |                |
| div_193            | DW_div_uns       | cla                |                |
| rem_194            | DW_div_uns       | cla                |                |
| add_x_216          | DW01_inc         | pparch (area,speed)                 |
| add_x_217          | DW01_inc         | pparch (area,speed)                 |
| add_x_218          | DW01_inc         | pparch (area,speed)                 |
| add_x_219          | DW01_inc         | pparch (area,speed)                 |
| add_x_220          | DW01_inc         | pparch (area,speed)                 |
| add_x_221          | DW01_inc         | pparch (area,speed)                 |
| add_x_222          | DW01_inc         | pparch (area,speed)                 |
| add_x_223          | DW01_inc         | pparch (area,speed)                 |
| gt_x_237           | DW_cmp           | apparch (area)     |                |
| lt_x_238           | DW_cmp           | apparch (area)     |                |
| gt_x_249           | DW_cmp           | apparch (area)     |                |
| lt_x_250           | DW_cmp           | apparch (area)     |                |
| gt_x_260           | DW_cmp           | apparch (area)     |                |
| lt_x_261           | DW_cmp           | apparch (area)     |                |
| gt_x_264           | DW_cmp           | apparch (area)     |                |
| lt_x_265           | DW_cmp           | apparch (area)     |                |
| mul_1              | DW_fp_mult       | str                |                |
| mul_2              | DW_fp_mult       | str                |                |
| mul_3              | DW_fp_mult       | str                |                |
| mul_4              | DW_fp_mult       | str                |                |
| mul_5              | DW_fp_mult       | str                |                |
| mul_6              | DW_fp_mult       | str                |                |
| mul_7              | DW_fp_mult       | str                |                |
| mul_8              | DW_fp_mult       | str                |                |
| mul_9              | DW_fp_mult       | str                |                |
| sum3_1             | DW_fp_sum3       | rtl                |                |
| sum3_2             | DW_fp_sum3       | rtl                |                |
| sum3_3             | DW_fp_sum3       | rtl                |                |
| sum3_4             | DW_fp_sum3       | rtl                |                |
| add_1              | DW_fp_add        | rtl                |                |
| exp_1              | DW_fp_exp        | rtl                |                |
| add_mom            | DW_fp_add        | rtl                |                |
| add_son            | DW_fp_add        | rtl                |                |
| recip_1            | DW_fp_recip      | rtl                |                |
| mult_1             | DW_fp_mult       | str                |                |
| selectmax          | DW_fp_sum4       | rtl                |                |
| comparemax         | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare8                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare7                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare6                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare5                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare4                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare3                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare2                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| Maxpooling/compare1                   |                    |                |
|                    | DW_fp_cmp        | rtl                |                |
| lt_x_1166          | DW_cmp           | apparch (area)     |                |
| gte_x_1167         | DW_cmp           | apparch (area)     |                |
| lt_x_1168          | DW_cmp           | apparch (area)     |                |
| gt_x_1169          | DW_cmp           | apparch (area)     |                |
| lt_x_1170          | DW_cmp           | apparch (area)     |                |
| gt_x_1171          | DW_cmp           | apparch (area)     |                |
| gt_x_1172          | DW_cmp           | apparch (area)     |                |
| lt_x_1173          | DW_cmp           | apparch (area)     |                |
| gt_x_1174          | DW_cmp           | apparch (area)     |                |
| lt_x_1175          | DW_cmp           | apparch (area)     |                |
| gt_x_1176          | DW_cmp           | apparch (area)     |                |
| gt_x_1177          | DW_cmp           | apparch (area)     |                |
| lt_x_1178          | DW_cmp           | apparch (area)     |                |
| gt_x_1179          | DW_cmp           | apparch (area)     |                |
| lt_x_1180          | DW_cmp           | apparch (area)     |                |
| gt_x_1181          | DW_cmp           | apparch (area)     |                |
| lt_x_1182          | DW_cmp           | apparch (area)     |                |
| lt_x_1183          | DW_cmp           | apparch (area)     |                |
| lt_x_1184          | DW_cmp           | apparch (area)     |                |
| gt_x_1185          | DW_cmp           | apparch (area)     |                |
| sub_x_137          | DW01_sub         | apparch (area)     |                |
| sub_x_123          | DW01_sub         | apparch (area)     |                |
| sub_x_130          | DW01_sub         | apparch (area)     |                |
| sub_x_116          | DW01_sub         | apparch (area)     |                |
| sub_x_171          | DW01_sub         | apparch (area)     |                |
| sub_x_192          | DW01_sub         | apparch (area)     |                |
| sub_x_55           | DW01_sub         | apparch (area)     |                |
| sub_x_189          | DW01_sub         | apparch (area)     |                |
| div_117            | DW_div_uns       | cla                |                |
| rem_118            | DW_div_uns       | cla3               |                |
| div_124            | DW_div_uns       | cla                |                |
| rem_125            | DW_div_uns       | cla3               |                |
| div_131            | DW_div_uns       | cla                |                |
| rem_132            | DW_div_uns       | cla3               |                |
| div_138            | DW_div_uns       | cla                |                |
| rem_139            | DW_div_uns       | cla3               |                |
| add_x_143          | DW01_add         | apparch (area)     |                |
| add_x_129          | DW01_add         | apparch (area)     |                |
| add_x_141          | DW01_add         | apparch (area)     |                |
| add_x_127          | DW01_add         | apparch (area)     |                |
| add_x_142          | DW01_inc         | apparch (area)     |                |
| add_x_128          | DW01_inc         | apparch (area)     |                |
| add_x_140          | DW01_inc         | apparch (area)     |                |
| add_x_126          | DW01_inc         | apparch (area)     |                |
| add_x_136          | DW01_add         | apparch (area)     |                |
| add_x_134          | DW01_add         | apparch (area)     |                |
| add_x_122          | DW01_add         | apparch (area)     |                |
| add_x_135          | DW01_inc         | apparch (area)     |                |
| add_x_120          | DW01_add         | apparch (area)     |                |
| add_x_133          | DW01_inc         | apparch (area)     |                |
| add_x_121          | DW01_inc         | apparch (area)     |                |
| add_x_119          | DW01_inc         | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | apparch (area)     |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gt_x_3             | DW_cmp           | pparch (area,speed)                 |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| gt_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gte_x_13           | DW_cmp           | pparch (area,speed)                 |
| gte_x_14           | DW_cmp           | pparch (area,speed)                 |
| gte_x_15           | DW_cmp           | pparch (area,speed)                 |
| gte_x_16           | DW_cmp           | pparch (area,speed)                 |
| gte_x_17           | DW_cmp           | pparch (area,speed)                 |
| eq_x_18            | DW_cmp           | apparch (area)     |                |
| eq_x_19            | DW_cmp           | apparch (area)     |                |
| eq_x_20            | DW_cmp           | apparch (area)     |                |
| eq_x_21            | DW_cmp           | apparch (area)     |                |
| eq_x_22            | DW_cmp           | apparch (area)     |                |
| sub_x_28           | DW01_sub         | pparch (area,speed)                 |
| sub_x_29           | DW01_sub         | pparch (area,speed)                 |
| sub_x_30           | DW01_sub         | pparch (area,speed)                 |
| add_x_31           | DW01_add         | apparch (area)     |                |
| ashr_34            | DW_rightsh       | astr (area)        |                |
| ash_35             | DW_leftsh        | astr (area)        |                |
| ashr_36            | DW_rightsh       | astr (area)        |                |
| ash_37             | DW_leftsh        | astr (area)        |                |
| ashr_38            | DW_rightsh       | astr (area)        |                |
| ash_39             | DW_leftsh        | astr (area)        |                |
| ash_48             | DW_leftsh        | astr (area)        |                |
| add_x_50           | DW01_add         | pparch (area,speed)                 |
| U1                 | DW_lzd           | cla                |                |
| U2                 | DW_lzd           | rtl                |                |
| add_x_65           | DW01_inc         | pparch (area,speed)                 |
| sub_x_49           | DW01_sub         | pparch (area,speed)                 |
| sub_x_66           | DW01_sub         | pparch (area,speed)                 |
| add_x_67           | DW01_add         | apparch (area)     |                |
| add_x_69           | DW01_add         | pparch (area,speed)                 |
| add_x_70           | DW01_add         | pparch (area,speed)                 |
| add_x_71           | DW01_add         | pparch (area,speed)                 |
| add_x_72           | DW01_add         | pparch (area,speed)                 |
| mult_x_2           | DW_mult_uns      | pparch (area,speed)                 |
|                    |                  | mult_arch: benc_radix4              |
| mult_x_3           | DW_mult_uns      | pparch (area,speed)                 |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_9            | DW_cmp           | apparch (area)     |                |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| U1                 | DW_fp_addsub     | rtl                |                |
| U1                 | DW_fp_addsub     | str                |                |
| mult_x_4           | DW_mult_uns      | pparch (area,speed)                 |
| sub_x_5            | DW01_sub         | apparch (area)     |                |
| gte_x_6            | DW_cmp           | apparch (area)     |                |
| add_x_9            | DW01_add         | pparch (area,speed)                 |
| add_x_11           | DW01_inc         | apparch (area)     |                |
| U1                 | DW01_ash         | astr (area)        |                |
| U2                 | DW_exp2          | rtl                |                |
| sub_x_16           | DW01_sub         | apparch (area)     |                |
| add_x_17           | DW01_dec         | apparch (area)     |                |
| sub_x_18           | DW01_sub         | pparch (area,speed)                 |
| add_x_19           | DW01_add         | apparch (area)     |                |
| add_x_20           | DW01_add         | apparch (area)     |                |
| U1                 | DW_fp_addsub     | rtl                |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| eq_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gte_x_17           | DW_cmp           | apparch (area)     |                |
| gte_x_18           | DW_cmp           | apparch (area)     |                |
| gte_x_19           | DW_cmp           | apparch (area)     |                |
| gte_x_20           | DW_cmp           | apparch (area)     |                |
| sub_x_21           | DW01_sub         | pparch (area,speed)                 |
| sub_x_22           | DW01_sub         | pparch (area,speed)                 |
| sub_x_23           | DW01_sub         | pparch (area,speed)                 |
| ashr_28            | DW_rightsh       | astr (area)        |                |
| ash_29             | DW_leftsh        | astr (area)        |                |
| ashr_30            | DW_rightsh       | astr (area)        |                |
| ash_31             | DW_leftsh        | astr (area)        |                |
| ashr_32            | DW_rightsh       | astr (area)        |                |
| ash_33             | DW_leftsh        | astr (area)        |                |
| gt_x_34            | DW_cmp           | apparch (area)     |                |
| gt_x_35            | DW_cmp           | apparch (area)     |                |
| gt_x_36            | DW_cmp           | apparch (area)     |                |
| ash_46             | DW_leftsh        | astr (area)        |                |
| add_x_47           | DW01_add         | pparch (area,speed)                 |
| U1                 | DW_lzd           | cla                |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| eq_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gte_x_17           | DW_cmp           | apparch (area)     |                |
| gte_x_18           | DW_cmp           | apparch (area)     |                |
| gte_x_19           | DW_cmp           | apparch (area)     |                |
| gte_x_20           | DW_cmp           | apparch (area)     |                |
| sub_x_21           | DW01_sub         | pparch (area,speed)                 |
| sub_x_22           | DW01_sub         | pparch (area,speed)                 |
| sub_x_23           | DW01_sub         | pparch (area,speed)                 |
| ashr_28            | DW_rightsh       | astr (area)        |                |
| ash_29             | DW_leftsh        | astr (area)        |                |
| ashr_30            | DW_rightsh       | astr (area)        |                |
| ash_31             | DW_leftsh        | astr (area)        |                |
| ashr_32            | DW_rightsh       | astr (area)        |                |
| ash_33             | DW_leftsh        | astr (area)        |                |
| gt_x_34            | DW_cmp           | pparch (area,speed)                 |
| gt_x_35            | DW_cmp           | pparch (area,speed)                 |
| gt_x_36            | DW_cmp           | pparch (area,speed)                 |
| ash_46             | DW_leftsh        | astr (area)        |                |
| add_x_47           | DW01_add         | pparch (area,speed)                 |
| U1                 | DW_lzd           | cla                |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| eq_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gte_x_17           | DW_cmp           | apparch (area)     |                |
| gte_x_18           | DW_cmp           | apparch (area)     |                |
| gte_x_19           | DW_cmp           | apparch (area)     |                |
| gte_x_20           | DW_cmp           | apparch (area)     |                |
| sub_x_21           | DW01_sub         | pparch (area,speed)                 |
| sub_x_22           | DW01_sub         | pparch (area,speed)                 |
| sub_x_23           | DW01_sub         | pparch (area,speed)                 |
| ashr_28            | DW_rightsh       | astr (area)        |                |
| ash_29             | DW_leftsh        | astr (area)        |                |
| ashr_30            | DW_rightsh       | astr (area)        |                |
| ash_31             | DW_leftsh        | astr (area)        |                |
| ashr_32            | DW_rightsh       | astr (area)        |                |
| ash_33             | DW_leftsh        | astr (area)        |                |
| gt_x_34            | DW_cmp           | pparch (area,speed)                 |
| gt_x_35            | DW_cmp           | pparch (area,speed)                 |
| gt_x_36            | DW_cmp           | pparch (area,speed)                 |
| ash_46             | DW_leftsh        | astr (area)        |                |
| add_x_47           | DW01_add         | pparch (area,speed)                 |
| U1                 | DW_lzd           | cla                |                |
| eq_x_4             | DW_cmp           | apparch (area)     |                |
| eq_x_5             | DW_cmp           | apparch (area)     |                |
| eq_x_6             | DW_cmp           | apparch (area)     |                |
| gte_x_17           | DW_cmp           | apparch (area)     |                |
| gte_x_18           | DW_cmp           | apparch (area)     |                |
| gte_x_19           | DW_cmp           | apparch (area)     |                |
| gte_x_20           | DW_cmp           | apparch (area)     |                |
| sub_x_21           | DW01_sub         | pparch (area,speed)                 |
| sub_x_22           | DW01_sub         | pparch (area,speed)                 |
| sub_x_23           | DW01_sub         | pparch (area,speed)                 |
| ashr_28            | DW_rightsh       | astr (area)        |                |
| ash_29             | DW_leftsh        | astr (area)        |                |
| ashr_30            | DW_rightsh       | astr (area)        |                |
| ash_31             | DW_leftsh        | astr (area)        |                |
| ashr_32            | DW_rightsh       | astr (area)        |                |
| ash_33             | DW_leftsh        | astr (area)        |                |
| gt_x_34            | DW_cmp           | pparch (area,speed)                 |
| gt_x_35            | DW_cmp           | pparch (area,speed)                 |
| gt_x_36            | DW_cmp           | pparch (area,speed)                 |
| ash_46             | DW_leftsh        | astr (area)        |                |
| add_x_47           | DW01_add         | pparch (area,speed)                 |
| U1                 | DW_lzd           | cla                |                |
| U2                 | DW01_ash         | astr (area)        |                |
| lt_x_1             | DW_cmp           | pparch (area,speed)                 |
| ashr_5             | DW_rightsh       | astr (area)        |                |
| ash_6              | DW_leftsh        | astr (area)        |                |
| ash_8              | DW_leftsh        | astr (area)        |                |
| add_x_9            | DW01_add         | apparch (area)     |                |
| add_x_16           | DW01_inc         | pparch (area,speed)                 |
| U2                 | DW_lzd           | cla                |                |
| U1                 | DW_norm          | rtl                |                |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | pparch (area,speed)                 |
| add_x_12           | DW01_add         | pparch (speed)     |                |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | rtl                |                |
| UL4                | DW_lzd           | cla                |                |
| UM1                | DW02_multp       | pparch (area,speed)                 |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (speed)     |                |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (area,speed)                 |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (speed)     |                |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (speed)     |                |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (speed)     |                |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (area,speed)                 |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (speed)     |                |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (speed)     |                |
|                    |                  | mult_arch: benc_radix4              |
| gte_x_2            | DW_cmp           | apparch (area)     |                |
| gte_x_4            | DW_cmp           | apparch (area)     |                |
| add_x_11           | DW01_add         | apparch (area)     |                |
| add_x_12           | DW01_add         | pparch (area,speed)                 |
| eq_x_14            | DW_cmp           | apparch (area)     |                |
| lt_x_21            | DW_cmp           | apparch (area)     |                |
| lt_x_23            | DW_cmp           | apparch (area)     |                |
| add_x_24           | DW01_add         | apparch (area)     |                |
| add_x_25           | DW01_add         | apparch (area)     |                |
| UL3                | DW_lzd           | cla                |                |
| UL4                | DW_lzd           | rtl                |                |
| UM1                | DW02_multp       | pparch (area,speed)                 |
|                    |                  | mult_arch: benc_radix4              |
| lt_x_1             | DW_cmp           | pparch (area,speed)                 |
| sub_x_4            | DW01_sub         | pparch (area,speed)                 |
| ashr_5             | DW_rightsh       | astr (area)        |                |
| ash_6              | DW_leftsh        | astr (area)        |                |
| ash_8              | DW_leftsh        | astr (area)        |                |
| add_x_12           | DW01_inc         | pparch (area,speed)                 |
| U1                 | DW_lzd           | rtl                |                |
| lt_x_1             | DW_cmp           | apparch (area)     |                |
| sub_x_4            | DW01_sub         | apparch (area)     |                |
| ashr_5             | DW_rightsh       | astr (area)        |                |
| ash_6              | DW_leftsh        | astr (area)        |                |
| ash_8              | DW_leftsh        | astr (area)        |                |
| add_x_12           | DW01_inc         | apparch (area)     |                |
| U1                 | DW_lzd           | rtl                |                |
| DP_OP_77_206_8530  | DP_OP_77_206_8530 | str (area,speed)  |                |
|                    |                  | mult_arch: and     |                |
|                    |                  | mult_arch: benc_radix4              |
|                    |                  | mult_arch: benc_radix4              |
| DP_OP_6433J1_148_3075                 |                    |                |
|                    | DP_OP_6433J1_148_3075 | str (area)    |                |
| DP_OP_6434J1_149_5102                 |                    |                |
|                    | DP_OP_6434J1_149_5102 | str (area)    |                |
| DP_OP_79J1_123_5437                   |                    |                |
|                    | DP_OP_79J1_123_5437 | str (area)      |                |
| DP_OP_95J1_131_8617                   |                    |                |
|                    | DP_OP_95J1_131_8617 | str (area,speed)                 |
|                    |                  | mult_arch: benc_radix4              |
|                    |                  | mult_arch: benc_radix4              |
| DP_OP_160J1_136_9276                  |                    |                |
|                    | DP_OP_160J1_136_9276 | str (speed)    |                |
| DP_OP_161J1_137_406                   |                    |                |
|                    | DP_OP_161J1_137_406 | str (area,speed)                 |
| DP_OP_160J1_139_9276                  |                    |                |
|                    | DP_OP_160J1_139_9276 | str (area,speed)                |
| DP_OP_161J1_140_406                   |                    |                |
|                    | DP_OP_161J1_140_406 | str (area,speed)                 |
| DP_OP_160J1_142_9276                  |                    |                |
|                    | DP_OP_160J1_142_9276 | str (area,speed)                |
| DP_OP_161J1_143_406                   |                    |                |
|                    | DP_OP_161J1_143_406 | str (area,speed)                 |
| DP_OP_160J1_145_9276                  |                    |                |
|                    | DP_OP_160J1_145_9276 | str (area,speed)                |
| DP_OP_161J1_146_406                   |                    |                |
|                    | DP_OP_161J1_146_406 | str (area,speed)                 |
| DP_OP_65J10_199_7885                  |                    |                |
|                    | DP_OP_65J10_199_7885 | str (area,speed)                |
| DP_OP_66J10_200_3163                  |                    |                |
|                    | DP_OP_66J10_200_3163 | str (area,speed)                |
| DP_OP_67J10_201_9752                  |                    |                |
|                    | DP_OP_67J10_201_9752 | str (area,speed)                |
| DP_OP_108J12_196_7736                 |                    |                |
|                    | DP_OP_108J12_196_7736 | str (area)    |                |
| DP_OP_109J12_197_8092                 |                    |                |
|                    | DP_OP_109J12_197_8092 | str (area,speed)               |
| DP_OP_108J9_155_7736                  |                    |                |
|                    | DP_OP_108J9_155_7736 | str (area)     |                |
| DP_OP_109J9_156_8092                  |                    |                |
|                    | DP_OP_109J9_156_8092 | str (area,speed)                |
| DP_OP_108J8_155_7736                  |                    |                |
|                    | DP_OP_108J8_155_7736 | str (area)     |                |
| DP_OP_109J8_156_8092                  |                    |                |
|                    | DP_OP_109J8_156_8092 | str (area,speed)                |
| DP_OP_108_159_7736 | DP_OP_108_159_7736 | str (area,speed) |                |
| DP_OP_109_160_8092 | DP_OP_109_160_8092 | str (area,speed) |                |
| DP_OP_108J3_155_7736                  |                    |                |
|                    | DP_OP_108J3_155_7736 | str (area)     |                |
| DP_OP_109J3_156_8092                  |                    |                |
|                    | DP_OP_109J3_156_8092 | str (area,speed)                |
| DP_OP_108_155_7736 | DP_OP_108_155_7736 | str (area)       |                |
| DP_OP_109_156_8092 | DP_OP_109_156_8092 | str (area,speed) |                |
| DP_OP_108J4_155_7736                  |                    |                |
|                    | DP_OP_108J4_155_7736 | str (area)     |                |
| DP_OP_109J4_156_8092                  |                    |                |
|                    | DP_OP_109J4_156_8092 | str (area,speed)                |
| DP_OP_108J6_155_7736                  |                    |                |
|                    | DP_OP_108J6_155_7736 | str (area,speed)                |
| DP_OP_109J6_156_8092                  |                    |                |
|                    | DP_OP_109J6_156_8092 | str (area,speed)                |
| DP_OP_108J7_155_7736                  |                    |                |
|                    | DP_OP_108J7_155_7736 | str (area)     |                |
| DP_OP_109J7_156_8092                  |                    |                |
|                    | DP_OP_109J7_156_8092 | str (area,speed)                |
| DP_OP_108J4_159_7736                  |                    |                |
|                    | DP_OP_108J4_159_7736 | str (area)     |                |
| DP_OP_109J4_160_8092                  |                    |                |
|                    | DP_OP_109J4_160_8092 | str (area,speed)                |
| DP_OP_49J1_126_3163                   |                    |                |
|                    | DP_OP_49J1_126_3163 | str (area,speed)                 |
| DP_OP_50J1_127_9752                   |                    |                |
|                    | DP_OP_50J1_127_9752 | str (area,speed)                 |
| DP_OP_49J1_134_3163                   |                    |                |
|                    | DP_OP_49J1_134_3163 | str (area)      |                |
| DP_OP_50J1_135_9752                   |                    |                |
|                    | DP_OP_50J1_135_9752 | str (area)      |                |
===============================================================================

1
