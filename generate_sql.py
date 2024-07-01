import random
import string
import sys

def generate_random_string(length=10):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

if len(sys.argv) != 2:
    print("Usage: python generate_sql.py <number_of_millions>")
    sys.exit(1)

num_millions = int(sys.argv[1])
num_records = num_millions * 1000000
output_file = f'insert_{num_millions}million_users.sql'

with open(output_file, 'w') as f:
    f.write('USE db;\n')  # データベース名を適切なものに変更してください
    f.write('START TRANSACTION;\n')

    for i in range(1, num_records + 1):
        name = generate_random_string()
        email = f"user{i}@example.com"
        password = generate_random_string(16)
        attributes = [generate_random_string() for _ in range(20)]
        attribute_values = ', '.join([f"'{attr}'" for attr in attributes])
        f.write(f"INSERT INTO `users` (`name`, `email`, `password`, `attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`, "
                f"`attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`, `attribute_k`, `attribute_l`, `attribute_m`, "
                f"`attribute_n`, `attribute_o`, `attribute_p`, `attribute_q`, `attribute_r`, `attribute_s`, `attribute_t`) VALUES "
                f"('{name}', '{email}', '{password}', {attribute_values});\n")

    f.write('COMMIT;\n')

