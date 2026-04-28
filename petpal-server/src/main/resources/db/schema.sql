CREATE TABLE user (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  phone VARCHAR(20) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  nickname VARCHAR(50) NOT NULL,
  avatar_url VARCHAR(255),
  bio VARCHAR(255),
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE user_follow (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  follower_id BIGINT NOT NULL,
  following_id BIGINT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_follow_pair (follower_id, following_id),
  CONSTRAINT chk_user_follow_not_self CHECK (follower_id <> following_id)
);

CREATE TABLE pet (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  owner_id BIGINT NOT NULL,
  name VARCHAR(50) NOT NULL,
  species VARCHAR(20) NOT NULL,
  breed VARCHAR(50),
  gender VARCHAR(20) NOT NULL,
  birthday DATE,
  weight DECIMAL(5,2),
  avatar_url VARCHAR(255),
  is_neutered TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted TINYINT NOT NULL DEFAULT 0,
  KEY idx_pet_owner_deleted (owner_id, deleted),
  UNIQUE KEY uk_pet_owner_id (owner_id, id),
  CONSTRAINT fk_pet_owner
    FOREIGN KEY (owner_id) REFERENCES user (id)
);

CREATE TABLE pet_health_record (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pet_id BIGINT NOT NULL,
  record_type VARCHAR(30) NOT NULL,
  title VARCHAR(100) NOT NULL,
  description VARCHAR(255),
  record_date DATE NOT NULL,
  next_date DATE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_pet_health_pet_record (pet_id, record_date, id),
  CONSTRAINT fk_pet_health_record_pet
    FOREIGN KEY (pet_id) REFERENCES pet (id)
);

CREATE TABLE pet_vaccine (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pet_id BIGINT NOT NULL,
  vaccine_name VARCHAR(100) NOT NULL,
  vaccinated_at DATE NOT NULL,
  next_due_at DATE,
  hospital VARCHAR(100),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_pet_vaccine_pet_date (pet_id, vaccinated_at, id),
  CONSTRAINT fk_pet_vaccine_pet
    FOREIGN KEY (pet_id) REFERENCES pet (id)
);

CREATE TABLE post (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  pet_id BIGINT,
  content VARCHAR(500) NOT NULL,
  like_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0,
  visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC',
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted TINYINT NOT NULL DEFAULT 0,
  KEY idx_post_user_status (user_id, status, deleted),
  KEY idx_post_feed (deleted, status, created_at, id),
  CONSTRAINT fk_post_user_pet
    FOREIGN KEY (user_id, pet_id) REFERENCES pet (owner_id, id)
);

CREATE TABLE post_image (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  image_url VARCHAR(1024) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_post_image_post_sort (post_id, sort_order),
  UNIQUE KEY uk_post_image_sort (post_id, sort_order),
  CONSTRAINT chk_post_image_sort_non_negative CHECK (sort_order >= 0)
);

CREATE TABLE post_like (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (post_id, user_id)
);

CREATE TABLE comment (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  parent_id BIGINT,
  user_id BIGINT NOT NULL,
  content VARCHAR(200) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_comment_post_parent_created (post_id, parent_id, created_at, id)
);

CREATE TABLE service_provider (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL,
  address VARCHAR(255) NOT NULL,
  phone VARCHAR(30),
  rating DECIMAL(2,1) NOT NULL DEFAULT 5.0,
  cover_url VARCHAR(255),
  business_hours VARCHAR(100),
  status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE service_item (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  provider_id BIGINT NOT NULL,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  duration INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted TINYINT NOT NULL DEFAULT 0,
  active_name_guard TINYINT GENERATED ALWAYS AS (
    CASE
      WHEN deleted = 0 THEN 1
      ELSE NULL
    END
  ),
  KEY idx_service_item_provider_deleted (provider_id, deleted),
  UNIQUE KEY uk_service_item_provider_id (provider_id, id),
  UNIQUE KEY uk_service_item_active_name (provider_id, name, active_name_guard),
  CONSTRAINT fk_service_item_provider
    FOREIGN KEY (provider_id) REFERENCES service_provider (id)
);

CREATE TABLE appointment (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_no VARCHAR(50) NOT NULL UNIQUE,
  user_id BIGINT NOT NULL,
  pet_id BIGINT NOT NULL,
  provider_id BIGINT NOT NULL,
  service_id BIGINT NOT NULL,
  status VARCHAR(30) NOT NULL,
  appointment_time DATETIME NOT NULL,
  remark VARCHAR(255),
  cancel_reason VARCHAR(255),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted TINYINT NOT NULL DEFAULT 0,
  active_duplicate_guard TINYINT GENERATED ALWAYS AS (
    CASE
      WHEN deleted = 0 AND status IN ('PENDING_CONFIRM', 'CONFIRMED') THEN 1
      ELSE NULL
    END
  ),
  KEY idx_appointment_user_deleted (user_id, deleted, appointment_time),
  KEY idx_appointment_provider_status (provider_id, status, appointment_time),
  UNIQUE KEY uk_appointment_active_duplicate (user_id, pet_id, provider_id, appointment_time, active_duplicate_guard),
  CONSTRAINT fk_appointment_user_pet
    FOREIGN KEY (user_id, pet_id) REFERENCES pet (owner_id, id),
  CONSTRAINT fk_appointment_provider_service
    FOREIGN KEY (provider_id, service_id) REFERENCES service_item (provider_id, id)
);

CREATE TABLE service_review (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  appointment_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  provider_id BIGINT NOT NULL,
  rating INT NOT NULL,
  content VARCHAR(255),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
