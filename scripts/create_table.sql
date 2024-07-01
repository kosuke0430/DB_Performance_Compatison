DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `email_verified_at` TIMESTAMP NULL,
    `attribute_a` VARCHAR(10) NULL,
    `attribute_b` VARCHAR(10) NULL,
    `attribute_c` VARCHAR(10) NULL,
    `attribute_d` VARCHAR(10) NULL,
    `attribute_e` VARCHAR(10) NULL,
    `attribute_f` VARCHAR(10) NULL,
    `attribute_g` VARCHAR(10) NULL,
    `attribute_h` VARCHAR(10) NULL,
    `attribute_i` VARCHAR(10) NULL,
    `attribute_j` VARCHAR(10) NULL,
    `attribute_k` VARCHAR(10) NULL,
    `attribute_l` VARCHAR(10) NULL,
    `attribute_m` VARCHAR(10) NULL,
    `attribute_n` VARCHAR(10) NULL,
    `attribute_o` VARCHAR(10) NULL,
    `attribute_p` VARCHAR(10) NULL,
    `attribute_q` VARCHAR(10) NULL,
    `attribute_r` VARCHAR(10) NULL,
    `attribute_s` VARCHAR(10) NULL,
    `attribute_t` VARCHAR(10) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_id (`id`),
    INDEX idx_users_attributes (`attribute_a`, `attribute_b`, `attribute_c`, `attribute_d`, `attribute_e`,
                                `attribute_f`, `attribute_g`, `attribute_h`, `attribute_i`, `attribute_j`,
                                `attribute_k`, `attribute_l`, `attribute_m`, `attribute_n`, `attribute_o`, `attribute_p`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;