INSERT INTO user (id, phone, password, nickname, avatar_url, bio) VALUES
(1, '13800000001', '$2a$10$Trga2O1gLdnL6g8mvggVK.kdQdkQkkcEQ8AWzaS1oTD.t4eZLKfzi', '小满', 'https://loremflickr.com/96/96/person?lock=9301', '猫狗照护日记'),
(2, '13800000002', '$2a$10$Trga2O1gLdnL6g8mvggVK.kdQdkQkkcEQ8AWzaS1oTD.t4eZLKfzi', '阿宁', 'https://loremflickr.com/96/96/person?lock=9302', '每周洗护记录');

INSERT INTO user_follow (follower_id, following_id) VALUES
(1, 2),
(2, 1);

INSERT INTO pet (id, owner_id, name, species, breed, gender, birthday, weight, avatar_url, is_neutered) VALUES
(1, 1, '糯米', 'CAT', '英短', 'FEMALE', '2022-05-01', 4.30, 'https://loremflickr.com/320/320/cat?lock=9201', 1),
(2, 1, '七七', 'DOG', '柯基', 'MALE', '2021-11-18', 10.80, 'https://loremflickr.com/320/320/dog?lock=9202', 0);

INSERT INTO pet_health_record (pet_id, record_type, title, description, record_date, next_date) VALUES
(1, 'CHECKUP', '年度体检', '血常规正常，食欲稳定。', '2026-02-18', '2027-02-18'),
(1, 'MEDICATION', '常规驱虫', '已完成常规体内驱虫。', '2026-03-01', '2026-06-01');

INSERT INTO pet_vaccine (pet_id, vaccine_name, vaccinated_at, next_due_at, hospital) VALUES
(1, '猫三联', '2025-04-18', '2026-04-11', '云朵宠物医院'),
(2, '狂犬疫苗', '2025-07-01', '2026-06-24', '云朵宠物医院');

INSERT INTO service_provider (id, name, type, address, phone, rating, cover_url, business_hours, status) VALUES
(1, '云朵宠物医院', 'HOSPITAL', '浦东丁香路 188 号', '021-12345678', 4.8, 'https://loremflickr.com/800/400/vet,pet?lock=101', '09:00-20:00', 'OPEN'),
(2, '泡泡宠物美容', 'GROOMING', '静安延平路 28 号', '021-87654321', 4.7, 'https://loremflickr.com/800/400/dog,grooming?lock=102', '10:00-21:00', 'OPEN'),
(3, '森林寄养之家', 'BOARDING', '徐汇莲花路 111 号', '021-99887766', 4.6, 'https://loremflickr.com/800/400/pet,boarding?lock=103', '08:00-22:00', 'OPEN');

INSERT INTO service_item (id, provider_id, name, price, duration) VALUES
(1, 1, '基础问诊', 59.00, 30),
(2, 1, '疫苗接种', 88.00, 20),
(3, 2, '基础洗护', 79.00, 60),
(4, 2, '全套美容', 199.00, 120),
(5, 3, '日间寄养', 128.00, 480),
(6, 3, '周末寄养', 299.00, 2880);

INSERT INTO appointment (id, order_no, user_id, pet_id, provider_id, service_id, status, appointment_time, remark) VALUES
(1, 'PP202603260001', 1, 1, 1, 2, 'CONFIRMED', '2026-12-29 10:30:00', '提前 10 分钟到店');

INSERT INTO post (id, user_id, pet_id, content, like_count, comment_count, visibility, status, created_at, updated_at) VALUES
(1, 1, 1, '糯米今天打完疫苗，回家后又趴在窗边晒太阳。#猫咪日常 #疫苗记录', 23, 1, 'PUBLIC', 'ACTIVE', '2026-03-24 18:20:00', '2026-03-24 18:20:00'),
(2, 1, 2, '七七做完全套美容，耳朵边修得特别精神。#狗狗日常 #洗护记录', 56, 1, 'PUBLIC', 'ACTIVE', '2026-03-23 13:10:00', '2026-03-23 13:10:00');

INSERT INTO post_image (post_id, image_url, sort_order) VALUES
(1, 'https://loremflickr.com/400/300/cat?lock=201', 0),
(1, 'https://loremflickr.com/400/300/pet,vaccine?lock=202', 1),
(2, 'https://loremflickr.com/400/300/dog,grooming?lock=203', 0);

INSERT INTO comment (id, post_id, parent_id, user_id, content, created_at) VALUES
(1, 1, NULL, 2, '看起来状态很好，恢复得很快。', '2026-03-24 19:10:00'),
(2, 1, 1, 1, '是的，医生也说整体很稳定。', '2026-03-24 19:18:00'),
(3, 2, NULL, 1, '美容师修得很仔细，七七看起来精神多了。', '2026-03-23 13:40:00');
