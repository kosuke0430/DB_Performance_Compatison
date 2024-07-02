# DB_Performance_Compatison
データベースの性能比較を行うプロジェクトです。

## このプロジェクトでできること
```
.
├── README.md
└── scripts
    ├── create_table.sql
    └── generate_sql.py
```
* create_table.sql
    <details>
    <summary>userテーブルの作成</summary>

    | カラム名 | 型 | 長さ | index |
    | --- | --- | --- | --- |
    | id | int |  |  |
    | name | VARCHAR | 255 |  |
    | email | VARCHAR | 255 |  |
    | password | VARCHAR | 255 |  |
    | email_verified_at | VARCHAR | 255 |  |
    | attribute_a | VARCHAR | 10 | Y |
    | attribute_b | VARCHAR | 10 | Y |
    | attribute_c | VARCHAR | 10 | Y |
    | attribute_d | VARCHAR | 10 | Y |
    | attribute_e | VARCHAR | 10 | Y |
    | attribute_f | VARCHAR | 10 | Y |
    | attribute_g | VARCHAR | 10 | Y |
    | attribute_h | VARCHAR | 10 | Y |
    | attribute_i | VARCHAR | 10 | Y |
    | attribute_j | VARCHAR | 10 | Y |
    | attribute_k | VARCHAR | 10 | Y |
    | attribute_l | VARCHAR | 10 | Y |
    | attribute_m | VARCHAR | 10 | Y |
    | attribute_n | VARCHAR | 10 | Y |
    | attribute_o | VARCHAR | 10 | Y |
    | attribute_p | VARCHAR | 10 | Y |
    | attribute_q | VARCHAR | 10 |  |
    | attribute_r | VARCHAR | 10 |  |
    | attribute_s | VARCHAR | 10 |  |
    | attribute_t | VARCHAR | 10 |  |
    | created_at | TIMESTAMP |  |  |
    | updated_at | TIMESTAMP |  |  |

    </details>
* generate_sql.py
    * 引数に数字を指定し、x00万件のデータを生成することができる

## テストレポート
1. [Dockerを用いた性能比較](./reports/docker_spec_comparision.md)
2. [AWS RDSを用いた性能比較](./reports/aws_rds_spec_comparisopn.md)