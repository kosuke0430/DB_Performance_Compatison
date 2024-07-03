# データベースの性能比較(Docker) 

## 比較方法
High Specコンテナ、Low Specコンテナの二種類を用意し、下記テストを行った
1. 大量データの書き込み速度の比較
    1. 100万件
    2. 300万件
    3. 500万件
2. 1.ののちに+1件の書き込み速度の比較
3. indexを用いたカラムの検索速度の比較
4. indexを用いていないカラムの検索速度の比較

## 使用したデータベース
### High Spec
メモリ：4GB
CPU：２コア
```
docker run --name mysql-high-spec \
    -e MYSQL_ROOT_PASSWORD=root \
    --memory=4g \
    --cpus=2 \
    -v ./highspec:/var/lib/mysql \
    -v ./scripts:/var/app \
    -d mysql:latest
```
### Low Spec
メモリ：1GB
CPU：1コア
```
docker run --name mysql-low-spec \
    -e MYSQL_ROOT_PASSWORD=root \
    --memory=1g \
    --cpus=1 \
    -v ./lowspec:/var/lib/mysql \
    -v ./scripts:/var/app \
    -d mysql:latest
```
## テスト結果
|  | Insert | +1 Insert | SELECT (indexあり) | SELECT (Indexなし) |
| --- | --- | --- | --- | --- |
| 100万 (High Spec) | 4m 50.045s | 0.02s | 0.00s | 1.33s |
| 100万 (Low Spec) | 6m 24.032s | 0.01s | 0.00s | 1.90s |
| 300万 (High Spec) | 17m 26.046s | 0.00s | 0.01s | 3.75s |
| 300万 (Low Spec) | 18m 56.206s | 0.01s | 0.02s | 5.87s |
| 500万 (High Spec) | 25m 51.648s | 0.02s | 0.01s | 5.86s |
| 500万 (Low Spec) | 29m 41.159s | 0.01s | 0.01s | 6.83s |

**Insert**

High Specの方が全体的に早く、100万件で1.32倍、300万件で1.08倍、500万件で1.14倍の差が出た。特に300万件の時は差が小さかったが、基本的にはHigh Specの方が早い。

ℹ️ メモリとコア数のどちらがスピードに起因するのか疑問に思ったので、lowspecのコア数を
higjspecと同じ2コアにしたところ、insertのスピードはほぼ同等になった

**+1 Insert**

100万から500万まで特に大きな変化は見られなかった。

**SELECT**

indexありのクエリは全体の件数に関わらず高速で返ってきた。indexなしのクエリは全件スキャンのため、件数が増えるごとに時間がかかり、Low Specの方が遅い。500万件のみLow Specの方が早かったが、理由は不明。
#### 詳細ログ
##### High Spec
<details>
<summary>100万件</summary>

 **insert**
```bash
bash-5.1# time mysql -u root -p db < /var/lib/mysql/insert_users.sql
Enter password:

real	4m50.045s
user	0m11.868s
sys	0m22.784s
```
**+1 insert**
```bash
mysql> INSERT INTO `users` (`name`, `email`, `password`, `email_verified_at`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`, `attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`, `attribute_k`, `attribute_l`, `attribute_m`, `attribute_n`, `attribute_o`, `attribute_p`, `attribute_q`, `attribute_r`, `attribute_s`, `attribute_t`) VALUES ('John Doe', 'john.doe@example.com', 'securepassword', NULL, 'attrA', 'attrB', 'attrC', 'attrD', 'attrE', 'attrF', 'attrG', 'attrH', 'attrI', 'attrJ', 'attrK', 'attrL', 'attrM', 'attrN', 'attrO', 'attrP', 'attrQ', 'attrR', 'attrS', 'attrT');
Query OK, 1 row affected (0.02 sec)
```
**SELECT**
* indexあり
    ```sql
    mysql> EXPLAIN SELECT * FROM users where attribute_a = "attrA";
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    |  1 | SIMPLE      | users | NULL       | ref  | idx_users_attributes | idx_users_attributes | 43      | const |    1 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    1 row in set, 1 warning (0.00 sec)
    
    mysql> SELECT * FROM users where attribute_a = "attrA";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 1000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:30:25 | 2024-06-23 12:30:25 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (0.00 sec)
    ```
* indexなし
    ```sql
    mysql> EXPLAIN SELECT * FROM users where name = "John Doe";
    +----+-------------+-------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
    +----+-------------+-------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    |  1 | SIMPLE      | users | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 956672 |    10.00 | Using where |
    +----+-------------+-------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    1 row in set, 1 warning (0.01 sec)
    
    mysql> SELECT * FROM users where name = "John Doe";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 1000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:30:25 | 2024-06-23 12:30:25 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (1.33 sec)
    ```
</details>
<details>
<summary>300万件</summary>

**insert**    
```sql
bash-5.1# time mysql -u root -p db < /var/app/insert_3million_users.sql
Enter password:

real	17m26.046s
user	0m31.902s
sys	1m7.133s
```
    
**+1 insert**   
```sql
mysql> INSERT INTO `users` (`name`, `email`, `password`, `email_verified_at`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`,
    ->                      `attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`, `attribute_k`, `attribute_l`, `attribute_m`,
    ->                      `attribute_n`, `attribute_o`, `attribute_p`, `attribute_q`, `attribute_r`, `attribute_s`, `attribute_t`)
    -> VALUES ('John Doe', 'john.doe@example.com', 'securepassword', NULL, 'attrA', 'attrB', 'attrC', 'attrD', 'attrE',
    ->         'attrF', 'attrG', 'attrH', 'attrI', 'attrJ', 'attrK', 'attrL', 'attrM', 'attrN', 'attrO', 'attrP',
    ->         'attrQ', 'attrR', 'attrS', 'attrT');
Query OK, 1 row affected (0.00 sec)
```
    
**SELECT**
    
* indexあり
    ```sql
    mysql> EXPLAIN SELECT * FROM users where attribute_a = "attrA";
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    |  1 | SIMPLE      | users | NULL       | ref  | idx_users_attributes | idx_users_attributes | 43      | const |    1 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    1 row in set, 1 warning (0.00 sec)
    
    mysql> SELECT * FROM users where attribute_a = "attrA";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 3000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 11:13:02 | 2024-06-23 11:13:02 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (0.01 sec)
    ```
    
* indexなし
    
    ```sql
    mysql> EXPLAIN SELECT * FROM users where name = "John Doe";
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra       |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    |  1 | SIMPLE      | users | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 2943265 |    10.00 | Using where |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    1 row in set, 1 warning (0.01 sec)
    
    mysql> SELECT * FROM users where name = "John Doe";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 3000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 11:13:02 | 2024-06-23 11:13:02 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (3.75 sec)
    ```

</details>
<details>
<summary>500万件</summary>

**insert**    
```sql
bash-5.1# time mysql -u root -p db < /var/app/insert_5million_users.sql
Enter password:

real	25m51.648s
user	0m52.970s
sys	1m55.707s
```
    
**+1 insert**
```sql
mysql> INSERT INTO `users` (`name`, `email`, `password`, `email_verified_at`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`,
    ->                      `attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`, `attribute_k`, `attribute_l`, `attribute_m`,
    ->                      `attribute_n`, `attribute_o`, `attribute_p`, `attribute_q`, `attribute_r`, `attribute_s`, `attribute_t`)
    -> VALUES ('John Doe', 'john.doe@example.com', 'securepassword', NULL, 'attrA', 'attrB', 'attrC', 'attrD', 'attrE',
    ->         'attrF', 'attrG', 'attrH', 'attrI', 'attrJ', 'attrK', 'attrL', 'attrM', 'attrN', 'attrO', 'attrP',
    ->         'attrQ', 'attrR', 'attrS', 'attrT');
Query OK, 1 row affected (0.02 sec)
```
    
**SELECT**
    
* indexあり    
    ```sql
    mysql> EXPLAIN SELECT * FROM users where attribute_a = "attrA";
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    |  1 | SIMPLE      | users | NULL       | ref  | idx_users_attributes | idx_users_attributes | 43      | const |    1 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    1 row in set, 1 warning (0.01 sec)
    
    mysql> SELECT * FROM users where attribute_a = "attrA";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 5000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:12:22 | 2024-06-23 12:12:22 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (0.01 sec)
    ```
    
* indexなし
    
    ```sql
    mysql> EXPLAIN SELECT * FROM users where name = "John Doe";
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra       |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    |  1 | SIMPLE      | users | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 4787972 |    10.00 | Using where |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    1 row in set, 1 warning (0.02 sec)
    
    mysql> SELECT * FROM users where name = "John Doe";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 5000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:12:22 | 2024-06-23 12:12:22 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (8.85 sec)
    ```
</details>
</details>

##### Low Spec
<details>
<summary>100万件</summary>

**insert**    
```bash
bash-5.1# time mysql -u root -p db < /var/lib/mysql/insert_users.sql
Enter password:

real	6m24.032s
user	0m11.594s
sys	0m25.381s
```
    
**+1 insert**   
```bash
mysql> INSERT INTO `users` (`name`, `email`, `password`, `email_verified_at`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`,
    ->                      `attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`, `attribute_k`, `attribute_l`, `attribute_m`,
    ->                      `attribute_n`, `attribute_o`, `attribute_p`, `attribute_q`, `attribute_r`, `attribute_s`, `attribute_t`)
    -> VALUES ('John Doe', 'john.doe@example.com', 'securepassword', NULL, 'attrA', 'attrB', 'attrC', 'attrD', 'attrE',
    ->         'attrF', 'attrG', 'attrH', 'attrI', 'attrJ', 'attrK', 'attrL', 'attrM', 'attrN', 'attrO', 'attrP',
    ->         'attrQ', 'attrR', 'attrS', 'attrT');
Query OK, 1 row affected (0.01 sec)
```
    
**SELECT**
    
* indexあり
    ```sql
    mysql> EXPLAIN SELECT * FROM users where attribute_a = "attrA";
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    |  1 | SIMPLE      | users | NULL       | ref  | idx_users_attributes | idx_users_attributes | 43      | const |    1 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    1 row in set, 1 warning (0.01 sec)
    
    mysql> SELECT * FROM users where attribute_a = "attrA";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 1000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 23:53:34 | 2024-06-23 23:53:34 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (0.00 sec)
    ```
    
* indexなし
    ```sql
    mysql> EXPLAIN SELECT * FROM users where name = "John Doe";
    +----+-------------+-------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
    +----+-------------+-------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    |  1 | SIMPLE      | users | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 956025 |    10.00 | Using where |
    +----+-------------+-------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    1 row in set, 1 warning (0.00 sec)
    
    mysql> SELECT * FROM users where name = "John Doe";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 1000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 23:53:34 | 2024-06-23 23:53:34 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (1.90 sec)
    ```
</details>
<details>
<summary>300万件</summary>

**insert**
```bash
bash-5.1# time mysql -uroot -proot db < /var/app/insert_3million_users.sql
mysql: [Warning] Using a password on the command line interface can be insecure.

real	18m56.206s
user	0m33.529s
sys	1m13.676s
```
    
**+1 insert**    
```sql
mysql> INSERT INTO `users` (`name`, `email`, `password`, `email_verified_at`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`,
    ->                      `attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`, `attribute_k`, `attribute_l`, `attribute_m`,
    ->                      `attribute_n`, `attribute_o`, `attribute_p`, `attribute_q`, `attribute_r`, `attribute_s`, `attribute_t`)
    -> VALUES ('John Doe', 'john.doe@example.com', 'securepassword', NULL, 'attrA', 'attrB', 'attrC', 'attrD', 'attrE',
    ->         'attrF', 'attrG', 'attrH', 'attrI', 'attrJ', 'attrK', 'attrL', 'attrM', 'attrN', 'attrO', 'attrP',
    ->         'attrQ', 'attrR', 'attrS', 'attrT');INSERT INTO `users` (`name`, `email`, `password`, `email_verified_at`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`,
Query OK, 1 row affected (0.01 sec)
```
    
**SELECT**
    
* indexあり
    ```sql
    mysql> EXPLAIN SELECT * FROM users where attribute_a = "attrA";
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    |  1 | SIMPLE      | users | NULL       | ref  | idx_users_attributes | idx_users_attributes | 43      | const |    1 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    1 row in set, 1 warning (0.01 sec)
    
    mysql> SELECT * FROM users where attribute_a = "attrA";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 3000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:12:21 | 2024-06-23 12:12:21 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (0.01 sec)
    ```
    
* indexなし
    ```sql
    mysql> EXPLAIN SELECT * FROM users where name = "John Doe";
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra       |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    |  1 | SIMPLE      | users | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 2868079 |    10.00 | Using where |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    1 row in set, 1 warning (0.02 sec)
    
    mysql> SELECT * FROM users where name = "John Doe";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 3000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:12:21 | 2024-06-23 12:12:21 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (5.87 sec)
    ```
</details>
<details>
<summary>500万件</summary>

**insert**    
```bash
mysql: [Warning] Using a password on the command line interface can be insecure.

real	29m41.159s
user	0m54.203s
sys	1m56.777s
```
    
**+1 insert**
    
```sql
mysql> INSERT INTO `users` (`name`, `email`, `password`, `email_verified_at`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`,
    ->                      `attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`, `attribute_k`, `attribute_l`, `attribute_m`,
    ->                      `attribute_n`, `attribute_o`, `attribute_p`, `attribute_q`, `attribute_r`, `attribute_s`, `attribute_t`)
    -> VALUES ('John Doe', 'john.doe@example.com', 'securepassword', NULL, 'attrA', 'attrB', 'attrC', 'attrD', 'attrE',
    ->         'attrF', 'attrG', 'attrH', 'attrI', 'attrJ', 'attrK', 'attrL', 'attrM', 'attrN', 'attrO', 'attrP',
    ->         'attrQ', 'attrR', 'attrS', 'attrT');
Query OK, 1 row affected (0.01 sec)
```
    
**SELECT**
    
* indexあり  
    ```sql
    mysql> EXPLAIN SELECT * FROM users where attribute_a = "attrA";
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    |  1 | SIMPLE      | users | NULL       | ref  | idx_users_attributes | idx_users_attributes | 43      | const |    1 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
    1 row in set, 1 warning (0.02 sec)
    
    mysql> SELECT * FROM users where attribute_a = "attrA";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 5000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:50:00 | 2024-06-23 12:50:00 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (0.01 sec)
    ```
    
* indexなし
    ```sql
    mysql> EXPLAIN SELECT * FROM users where name = "John Doe";
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra       |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    |  1 | SIMPLE      | users | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 4904508 |    10.00 | Using where |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    1 row in set, 1 warning (0.01 sec)
    
    mysql> SELECT * FROM users where name = "John Doe";
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | id      | name     | email                | password       | email_verified_at | attribute_a | attribute_b | attribute_c | attribute_d | attribute_e | attribute_f | attribute_g | attribute_h | attribute_i | attribute_j | attribute_k | attribute_l | attribute_m | attribute_n | attribute_o | attribute_p | attribute_q | attribute_r | attribute_s | attribute_t | created_at          | updated_at          |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    | 5000001 | John Doe | john.doe@example.com | securepassword | NULL              | attrA       | attrB       | attrC       | attrD       | attrE       | attrF       | attrG       | attrH       | attrI       | attrJ       | attrK       | attrL       | attrM       | attrN       | attrO       | attrP       | attrQ       | attrR       | attrS       | attrT       | 2024-06-23 12:50:00 | 2024-06-23 12:50:00 |
    +---------+----------+----------------------+----------------+-------------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+-------------+---------------------+---------------------+
    1 row in set (6.83 sec)
    ```
</details>
